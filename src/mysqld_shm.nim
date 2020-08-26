import os
import osproc
import strformat
import strutils
import threadpool

const dbPath = "/dev/shm/mysql_var"
const sysUserName = "mysql"
const chownCmd = fmt"chown {sysUserName}:{sysUserName} " & dbPath
const runuserParams = ["-u", sysUserName, "-g", sysUserName, "mysqld"]
const appUserName = "'example_user'@'localhost'"
const appUserPass = "'example_pass'"

const initCmd = join(
    [
        "mariadb-install-db",
        "--user=" & sysUserName,
        "--basedir=/usr",
        "--datadir=" & dbPath,
    ],
    " ",
)

const sql = join(
    [
        fmt"CREATE USER {appUserName} IDENTIFIED BY {appUserPass}",
        fmt"GRANT ALL PRIVILEGES ON *.* TO {appUserName}",
        "FLUSH PRIVILEGES",
    ],
    "; ",
)

if existsOrCreateDir(dbPath):
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
    args = @runuserParams & commandLineParams(),
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
