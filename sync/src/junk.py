host = "localhost"
port = "1521"
service_name_really_lksdjffffffffffffffffffffffffffffffffffffffffffff = (
    "service_name"
)
username = "username"
password = "password"


db_dsn = (
    "oracle+oracledb://{0}:{1}@"
    f"{host}:"
    f"{port}/"
    f"{service_name_really_lksdjffffffffffffffffffffffffffffffffffffffffffff}"
)
print("database dsn is %s", db_dsn)
# ENGINE_PATH_WIN_AUTH = DIALECT + '+' + SQL_DRIVER + '://' + USERNAME + ':' + PASSWORD +'@' + HOST + ':' + str(PORT) + '/?service_name=' + SERVICE
deleteme = db_dsn.format(
    username,
    password,
)
print("deleteme is %s", deleteme)
