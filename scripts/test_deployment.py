import requests
import argparse
from azure.ai.ml import MLClient
from azure.identity import DefaultAzureCredential
import os
from dotenv import load_dotenv
load_dotenv()
def get_client() -> MLClient:
  # check if env variables are set and initialize client from those
  client = MLClient(DefaultAzureCredential(), os.environ["AZURE_SUBSCRIPTION_ID"], os.environ["AZURE_RESOURCE_GROUP"], os.environ["AZUREAI_PROJECT_NAME"])
  if client:
    return client
  
  raise Exception("Necessary values for subscription, resource group, and project are not defined")

def invoke_deployment(endpoint_name: str, query: str, stream: bool = False):
    client = get_client()
    
    accept_header = "text/event-stream" if stream else "application/json"

    scoring_url = client.online_endpoints.get(endpoint_name).scoring_uri

    headers = {
        "Content-Type": "application/json",
        "Authorization": f"Bearer {client._credential.get_token('https://ml.azure.com').token}",
        "Accept": accept_header
    }

    response = requests.post(
        scoring_url,
        headers=headers,
        json={"chat_input": query, "stream": stream}
    )

    if stream:
        for item in response.iter_lines(chunk_size=None):
            print(item)
    else:
        response_data = response.json()
        chat_reply = response_data.get('reply', 'No reply in response')
        print(f"\n{chat_reply}")

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Invoke a deployment endpoint.")
    parser.add_argument("--endpoint-name", required=True, help="Endpoint name to use when deploying or invoking the flow")
    parser.add_argument("--query", help="Query to test the deployment with")
    parser.add_argument("--stream", action="store_true", help="Whether the response should be streamed or not")
    
    args = parser.parse_args()

    query = args.query if args.query else "who is the CEO of sqd ?"

    invoke_deployment(args.endpoint_name, query=query, stream=args.stream)
