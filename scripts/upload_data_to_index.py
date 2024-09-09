import os
from dotenv import load_dotenv
from azure.ai.ml import MLClient
from azure.identity import DefaultAzureCredential
from azure.ai.ml.entities import Index

from promptflow.rag.config import (
    LocalSource,
    AzureAISearchConfig,
    EmbeddingsModelConfig,
    ConnectionConfig,
)

from pathlib import Path
from promptflow.rag import build_index

load_dotenv()

client = MLClient(
    DefaultAzureCredential(),
    os.getenv("AZURE_SUBSCRIPTION_ID"),
    os.getenv("AZURE_RESOURCE_GROUP"),
    os.getenv("AZUREAI_PROJECT_NAME"),
)

data_directory = Path(__file__).resolve().parent / "../data"
files = list(data_directory.glob('*')) if data_directory.exists() else None

if files:
    print(f"Data directory '{data_directory}' exists and contains {len(files)} files.")
elif files is not None:
    print(f"Data directory '{data_directory}' exists but is empty.")
    exit()
else:
    print(f"Data directory '{data_directory}' does not exist.")
    exit()

index_name = os.getenv("AZUREAI_SEARCH_INDEX_NAME")
index_path = build_index(
    name=index_name,  
    vector_store="azure_ai_search",
    embeddings_model_config=EmbeddingsModelConfig(
        model_name=os.getenv("AZURE_OPENAI_EMBEDDING_DEPLOYMENT"),
        deployment_name=os.getenv("AZURE_OPENAI_EMBEDDING_DEPLOYMENT"),
        connection_config=ConnectionConfig(
            subscription_id=client.subscription_id,
            resource_group_name=client.resource_group_name,
            workspace_name=client.workspace_name,
            connection_name=os.getenv("AZURE_OPENAI_CONNECTION_NAME"),
        ),
    ),
    input_source=LocalSource(input_data=data_directory),
    index_config=AzureAISearchConfig(
        ai_search_index_name=index_name,
        ai_search_connection_config=ConnectionConfig(
            subscription_id=client.subscription_id,
            resource_group_name=client.resource_group_name,
            workspace_name=client.workspace_name,
            connection_name=os.getenv("AZURE_SEARCH_CONNECTION_NAME"),
        ),
    ),
    tokens_per_chunk=800,
    token_overlap_across_chunks=0,
)

client.indexes.create_or_update(Index(name=index_name, path=index_path))