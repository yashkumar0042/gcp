import tweepy
import json
import os
from google.cloud import bigquery
from google.oauth2 import service_account
from google.cloud import pubsub_v1

project_id = "docker-build-new"
subscription_name = "bq_subscription"
dataset_id = "us_dataset"
table_id = "tweets_data"

def my_tweets():
    curr_dir = os.getcwd()
    key_path = curr_dir + '/keys.json'
    auth = service_account.Credentials.from_service_account_file(filename=key_path)
    consumer_key, consumer_secret, access_token, access_token_secret = auth_creds(auth)
    tweetsPerQry = 10
    maxTweets = 100
    hashtag = "#IKEA"

    authentication = tweepy.OAuthHandler(consumer_key, consumer_secret)
    authentication.set_access_token(access_token, access_token_secret)
    api = tweepy.API(authentication, wait_on_rate_limit=True)
    maxId = -1
    tweetCount = 0

    subscriber = pubsub_v1.SubscriberClient()
    subscription_path = subscriber.subscription_path(project_id, subscription_name)

    while tweetCount < maxTweets:
        if maxId <= 0:
            newTweets = api.search_tweets(q=hashtag, count=tweetsPerQry, result_type="recent", tweet_mode="extended", lang="en")
        else:
            newTweets = api.search_tweets(q=hashtag, count=tweetsPerQry, max_id=str(maxId - 1), result_type="recent",
                                          tweet_mode="extended", lang="en")

        if not newTweets:
            print("No new tweets..!")
            break

        values = []

        for tweet in newTweets:
            tweet_id = tweet.id
            created_at = tweet.created_at
            text = tweet.full_text
            user_id = tweet.user.id
            tweetz = {"hashtag": hashtag, "tweet_id": tweet_id, "created_at": created_at, "text": text, "user_id": user_id}
            values.append(tweetz)

        tweetCount += len(newTweets)
        maxId = newTweets[-1].id

        print(values)
        if values:
            publish_to_ps(values, subscriber, subscription_path)

def auth_creds(auth):
    secret_client = secretmanager.SecretManagerServiceClient(credentials=auth)
    consumer_key = secret_client.access_secret_version(name=f"projects/{project_id}/secrets/consumer_key/versions/latest")
    consumer_key_response = consumer_key.payload.data.decode("UTF-8")
    consumer_secret = secret_client.access_secret_version(name=f"projects/{project_id}/secrets/consumer_secret/versions/latest")
    consumer_secret_response = consumer_secret.payload.data.decode("UTF-8")
    access_token = secret_client.access_secret_version(name=f"projects/{project_id}/secrets/access_token/versions/latest")
    access_token_response = access_token.payload.data.decode("UTF-8")
    access_token_secret = secret_client.access_secret_version(name=f"projects/{project_id}/secrets/access_token_secret/versions/latest")
    access_token_secret_response = access_token_secret.payload.data.decode("UTF-8")
    return consumer_key_response, consumer_secret_response, access_token_response, access_token_secret_response

def publish_to_ps(value, subscriber, subscription_path):
    topic = "tweet_batch"
    pb_client = pubsub_v1.PublisherClient(credentials=auth)
    topic_path = pb_client.topic_path(project=project_id, topic=topic)

    # Publish to Pub/Sub
    data = json.dumps(value).encode("utf-8")
    publish = pb_client.publish(topic=topic_path, data=data)
    print(publish.result())

    # Pull from Pub/Sub and insert into BigQuery
    pull_from_pubsub(subscriber, subscription_path, max_messages=1)

def pull_from_pubsub(subscriber, subscription_path, max_messages):
    response = subscriber.pull(subscription=subscription_path, max_messages=max_messages)

    # Process received messages
    if response.received_messages:
        for received_message in response.received_messages:
            message_data = received_message.message.data.decode("utf-8")
            rows = json.loads(message_data)  # Use json.loads instead of eval
            insert_into_bigquery(rows)

            # Acknowledge the message
            subscriber.acknowledge(subscription=subscription_path, ack_ids=[received_message.ack_id])

def insert_into_bigquery(rows):
    client = bigquery.Client()
    dataset_ref = client.dataset(dataset_id)
    table_ref = dataset_ref.table(table_id)

    errors = client.insert_rows(table_ref, rows)

    if errors:
        print(f"Errors while inserting into BigQuery: {errors}")
    else:
        print("Data inserted into BigQuery successfully!")

if __name__ == '__main__':
    my_tweets()
