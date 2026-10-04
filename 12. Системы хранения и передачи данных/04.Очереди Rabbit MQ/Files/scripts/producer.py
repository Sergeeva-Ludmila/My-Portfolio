#!/usr/bin/env python3
import os
import sys
import pika

HOST = os.environ.get("RABBITMQ_HOST", "rmq01")
PORT = int(os.environ.get("RABBITMQ_PORT", "5672"))
QUEUE_NAME = os.environ.get("QUEUE_NAME", "hello")
USERNAME = os.environ.get("RABBITMQ_USER", "mila")
PASSWORD = os.environ.get("RABBITMQ_PASS", "mila")

def main():
    message = " ".join(sys.argv[1:]) if len(sys.argv) > 1 else "Hello World!"
    credentials = pika.PlainCredentials(USERNAME, PASSWORD)
    parameters = pika.ConnectionParameters(host=HOST, port=PORT, credentials=credentials)
    connection = pika.BlockingConnection(parameters)
    channel = connection.channel()
    channel.queue_declare(queue=QUEUE_NAME, durable=True)
    channel.basic_publish(
        exchange="",
        routing_key=QUEUE_NAME,
        body=message.encode("utf-8"),
        properties=pika.BasicProperties(delivery_mode=2)
    )
    print(f"[x] Sent to {HOST}:{PORT} queue='{QUEUE_NAME}': {message}")
    connection.close()

if __name__ == "__main__":
    main()
