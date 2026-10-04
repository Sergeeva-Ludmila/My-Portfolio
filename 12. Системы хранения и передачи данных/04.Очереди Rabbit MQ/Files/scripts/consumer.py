#!/usr/bin/env python3
import os
import pika

HOST = os.environ.get("RABBITMQ_HOST", "rmq01")
PORT = int(os.environ.get("RABBITMQ_PORT", "5672"))
QUEUE_NAME = os.environ.get("QUEUE_NAME", "hello")
USERNAME = os.environ.get("RABBITMQ_USER", "mila")
PASSWORD = os.environ.get("RABBITMQ_PASS", "mila")

print(f"DEBUG: connecting to HOST={HOST}, PORT={PORT}, USER={USERNAME}")

def callback(ch, method, properties, body):
    print(f"[*] Received from {HOST}:{PORT} queue='{QUEUE_NAME}': {body.decode('utf-8')}")

def main():
    credentials = pika.PlainCredentials(USERNAME, PASSWORD)
    parameters = pika.ConnectionParameters(host=HOST, port=PORT, credentials=credentials)
    connection = pika.BlockingConnection(parameters)
    channel = connection.channel()
    channel.queue_declare(queue=QUEUE_NAME, durable=True)
    channel.basic_consume(queue=QUEUE_NAME, on_message_callback=callback, auto_ack=True)
    print(f"[*] Waiting for messages on {HOST}:{PORT} queue='{QUEUE_NAME}'. To exit press CTRL+C")
    channel.start_consuming()

if __name__ == "__main__":
    main()

