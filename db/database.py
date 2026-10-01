import pymysql

def db():
    return pymysql.connect(
        host='192.168.10.36',
        user='root',
        password='qwer1234',
        database='step_seoul',
        charset='utf8'
    )