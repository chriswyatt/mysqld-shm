import os
import osproc
import strutils
import threadpool

const mysqlVarPath = "/dev/shm/mysql_var"

const chownCmd = "chown mysql:mysql " & mysqlVarPath

const runuserParams = @["-u", "mysql", "-g", "mysql", "mysqld"]

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

block:
    let output = execProcess(
        "mysql",
        args = ["-u", "root", "--execute=" & sql],
        options = {poEchoCmd, poStdErrToStdOut, poUsePath},
    )
    echo output

block:
    let exitCode = execCmd("mysqladmin shutdown")
    if exitCode != 0:
        quit(QuitFailure)

sync()
let mysqldOutput = ^mysqldFlowVar
echo mysqldOutput
