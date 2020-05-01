import os
import osproc
import strformat
import strutils
import threadpool

const mysqlVarPath = "/dev/shm/mysql_var"
const mysqlUserName = "mysql"
const chownCmd = fmt"chown {mysqlUserName}:{mysqlUserName} " & mysqlVarPath

const runuserParams = @[
    "-u", mysql_user_name,
    "-g", mysql_user_name,
    "mysqld",
]

const initCmd = join(
    [
        "mariadb-install-db",
        "--user=mysql",
        "--basedir=/usr",
        "--datadir=" & mysqlVarPath,
    ],
    " ",
)

const sql = join(
    [
        "CREATE USER 'portal_app'@'localhost' IDENTIFIED BY 'portal_app'",
        "GRANT ALL PRIVILEGES ON *.* TO 'portal_app'@'localhost'",
        "FLUSH PRIVILEGES",
    ],
    "; ",
)

if existsOrCreateDir(mysql_var_path):
    quit(QuitSuccess)

block:
    let exitCode = execCmd(chownCmd)
    if exitCode != 0:
        quit(exit_code)

block:
    let exitCode = execCmd(initCmd)
    if exitCode != 0:
        quit(exit_code)

let mysqldFlowVar = spawn execProcess(
    "runuser",
    args = runuserParams & commandLineParams(),
    options = {poEchoCmd, poStdErrToStdOut, poUsePath},
)

for i in 0..<40:
    sleep(250)
    if execCmd("mysqladmin ping") == 0:
        break

echo execProcess(
    "mysql",
    args = ["-u", "root", "--execute=" & sql],
    options = {poEchoCmd, poStdErrToStdOut, poUsePath},
)

block:
    let exitCode = execCmd("mysqladmin shutdown")
    if exitCode != 0:
        quit(exitCode)

sync()
let mysqldOutput = ^mysqldFlowVar
echo mysqldOutput
