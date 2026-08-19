import os
import time
from fastapi import FastAPI
from pydantic import BaseModel
import psycopg2
import redis

app = FastAPI()

DB_HOST = os.getenv("DB_HOST", "localhost")
DB_NAME = os.getenv("DB_NAME", "appdb")
DB_USER = os.getenv("DB_USER", "postgres")
DB_PASS = os.getenv("DB_PASS", "postgres")
REDIS_HOST = os.getenv("REDIS_HOST", "localhost")

# Inicijalizacija Redis-a
cache = redis.Redis(host=REDIS_HOST, port=6379, db=0)

def get_db_connection():
    return psycopg2.connect(
        host=DB_HOST, database=DB_NAME, user=DB_USER, password=DB_PASS
    )

class Task(BaseModel):
    title: str

@app.get("/health")
def health_check():
    return {"status": "healthy"}

@app.get("/tasks")
def read_tasks():
    # Provera keša
    cached_count = cache.get("task_views")
    views = int(cached_count) if cached_count else 0
    cache.set("task_views", views + 1)

    try:
        conn = get_db_connection()
        cur = conn.cursor()
        cur.execute("SELECT id, title FROM tasks;")
        tasks = cur.fetchall()
        cur.close()
        conn.close()
        return {"tasks": tasks, "views_counter": views + 1}
    except Exception as e:
        return {"error": str(e), "views_counter": views + 1}

@app.post("/tasks")
def create_task(task: Task):
    try:
        conn = get_db_connection()
        cur = conn.cursor()
        cur.execute("CREATE TABLE IF NOT EXISTS tasks (id SERIAL PRIMARY KEY, title VARCHAR(255));")
        cur.execute("INSERT INTO tasks (title) VALUES (%s);", (task.title,))
        conn.commit()
        cur.close()
        conn.close()
        return {"status": "created", "title": task.title}
    except Exception as e:
        return {"error": str(e)}