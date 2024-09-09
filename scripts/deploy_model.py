import os
from dotenv import load_dotenv

from azure.ai.ml import MLClient
from azure.identity import DefaultAzureCredential
from azure.ai.ml.entities import ManagedOnlineEndpoint, ManagedOnlineDeployment, Model, Environment, BuildContext

# Load environment variables
load_dotenv()

# Initialize MLClient
client = MLClient(
    DefaultAzureCredential(),
    os.getenv("AZURE_SUBSCRIPTION_ID"),
    os.getenv("AZURE_RESOURCE_GROUP"),
    os.getenv("AZUREAI_PROJECT_NAME"),
)


# Constants
endpoint_name = "sqd-endpoint"
deployment_name = "sqd-deployment"
script_dir = os.path.dirname(os.path.abspath(__file__))
copilot_path = os.path.join(script_dir, "sqd_flow")

# Define endpoint
endpoint = ManagedOnlineEndpoint(
    name=endpoint_name,
    properties={"enforce_access_to_default_secret_stores": "enabled"},
    auth_mode="aad_token",
)

# Define deployment
deployment = ManagedOnlineDeployment(
    name=deployment_name,
    endpoint_name=endpoint_name,
    model=Model(
        name="copilot_flow_model",
        path=copilot_path,
        properties=[
            ["azureml.promptflow.source_flow_id", "basic-chat"],
            ["azureml.promptflow.mode", "chat"],
            ["azureml.promptflow.chat_input", "chat_input"],
            ["azureml.promptflow.chat_output", "reply"],
        ],
    ),
    environment=Environment(
        build=BuildContext(path=copilot_path),
        inference_config={
            "liveness_route": {"path": "/health", "port": 8080},
            "readiness_route": {"path": "/health", "port": 8080},
            "scoring_route": {"path": "/score", "port": 8080},
        },
    ),
    instance_type="Standard_DS3_v2",
    instance_count=1,
    environment_variables={
        "PRT_CONFIG_OVERRIDE": f"deployment.subscription_id={client.subscription_id},deployment.resource_group={client.resource_group_name},deployment.workspace_name={client.workspace_name},deployment.endpoint_name={endpoint_name},deployment.deployment_name={deployment_name}",
        "AZURE_OPENAI_ENDPOINT": client.connections.get(os.getenv("AZURE_OPENAI_CONNECTION_NAME")).api_base,
        "AZURE_SEARCH_ENDPOINT": client.connections.get(os.getenv("AZURE_SEARCH_CONNECTION_NAME")).api_base,
        "AZURE_OPENAI_API_VERSION": os.getenv("AZURE_OPENAI_API_VERSION"),
        "AZURE_OPENAI_CHAT_DEPLOYMENT": os.getenv("AZURE_OPENAI_CHAT_DEPLOYMENT"),
        "AZURE_OPENAI_EVALUATION_DEPLOYMENT": os.getenv("AZURE_OPENAI_EVALUATION_DEPLOYMENT"),
        "AZURE_OPENAI_EMBEDDING_DEPLOYMENT": os.getenv("AZURE_OPENAI_EMBEDDING_DEPLOYMENT"),
        "AZUREAI_SEARCH_INDEX_NAME": os.getenv("AZUREAI_SEARCH_INDEX_NAME"),
        "AZURE_OPENAI_API_KEY": client.connections.get(os.getenv("AZURE_OPENAI_CONNECTION_NAME"), populate_secrets=True).api_key,
        "AZURE_SEARCH_API_KEY": client.connections.get(os.getenv("AZURE_SEARCH_CONNECTION_NAME"), populate_secrets=True).api_key,
    },
)

# Deploy endpoint and deployment
client.begin_create_or_update(endpoint).result()
client.begin_create_or_update(deployment).result()

# Update endpoint traffic
endpoint.traffic = {deployment_name: 100}
client.begin_create_or_update(endpoint).result()

# Get deployment URL
def get_ai_studio_url_for_deploy(client: MLClient, endpoint_name: str, deployment_name: str) -> str:
    studio_base_url = "https://ai.azure.com"
    return f"{studio_base_url}/projectdeployments/realtime/{endpoint_name}/{deployment_name}/detail?wsid=/subscriptions/{client.subscription_id}/resourceGroups/{client.resource_group_name}/providers/Microsoft.MachineLearningServices/workspaces/{client.workspace_name}&deploymentName={deployment_name}"

# Print deployment details
print("\n ~~~Deployment details~~~")
print(f"Your online endpoint name is: {endpoint_name}")
print(f"Your deployment name is: {deployment_name}")

print("\n ~~~Test in the Azure AI Studio~~~")
print("\n Follow this link to your deployment in the Azure AI Studio:")
print(get_ai_studio_url_for_deploy(client, endpoint_name, deployment_name))
