import os
from dotenv import load_dotenv
from pathlib import Path
from typing import TypedDict

from promptflow.core import Prompty, AzureOpenAIModelConfiguration
from promptflow.tracing import trace
from openai import AzureOpenAI
from azure.core.credentials import AzureKeyCredential
from azure.search.documents import SearchClient
from azure.search.documents.models import VectorizedQuery

load_dotenv()

# Helper function to initialize the AzureOpenAI client
def initialize_aoai_client() -> AzureOpenAI:
    return AzureOpenAI(
        azure_endpoint=os.getenv("AZURE_OPENAI_ENDPOINT"),
        api_version=os.getenv("AZURE_OPENAI_API_VERSION"),
        api_key=os.getenv("AZURE_OPENAI_API_KEY"),
    )


# Helper function to initialize the search client
def initialize_search_client() -> SearchClient:
    key = os.environ["AZURE_SEARCH_API_KEY"]
    index_name = os.getenv("AZUREAI_SEARCH_INDEX_NAME")

    return SearchClient(
        endpoint=os.getenv("AZURE_SEARCH_ENDPOINT"),
        credential=AzureKeyCredential(key),
        index_name=index_name,
    )


# <get_documents>
@trace
def get_documents(search_query: str, num_docs=3):
    search_client = initialize_search_client()
    aoai_client = initialize_aoai_client()
    print("OPENAI:")
    print(os.getenv("AZURE_OPENAI_ENDPOINT"))
    print(os.getenv("AZURE_OPENAI_EMBEDDING_DEPLOYMENT"))
    print(aoai_client.base_url)
    # Generate vector embedding of the user's query
    embedding = aoai_client.embeddings.create(
        input=search_query, model=os.getenv("AZURE_OPENAI_EMBEDDING_DEPLOYMENT")
    )
    embedding_to_query = embedding.data[0].embedding

    # Vector search on the index
    vector_query = VectorizedQuery(
        vector=embedding_to_query, k_nearest_neighbors=num_docs, fields="contentVector"
    )
    results = search_client.search(
        search_text="", vector_queries=[vector_query], select=["id", "content"]
    )

    # Combine search results into context string
    context = "\n".join(
        f">>> From: {result['id']}\n{result['content']}" for result in results
    )

    return context


# Data structure for chat response
class ChatResponse(TypedDict):
    context: str
    reply: str


# Get chat response
def get_chat_response(chat_input: str, chat_history: list = []) -> ChatResponse:
    model_config = AzureOpenAIModelConfiguration(
        azure_deployment=os.getenv("AZURE_OPENAI_CHAT_DEPLOYMENT"),
        api_version=os.getenv("AZURE_OPENAI_API_VERSION"),
        azure_endpoint=os.getenv("AZURE_OPENAI_ENDPOINT"),
        api_key=os.getenv("AZURE_OPENAI_API_KEY"),
    )

    search_query = chat_input

    # Extract intent from chat history if provided
    if chat_history:
        intent_prompty = Prompty.load(
            f"{Path(__file__).parent.absolute().as_posix()}/queryIntent.prompty",
            model={"configuration": model_config, "parameters": {"max_tokens": 256}},
        )
        search_query = intent_prompty(query=chat_input, chat_history=chat_history)

    # Retrieve relevant documents based on query and chat history
    documents = get_documents(search_query, 3)
    
    # Generate chat response using the context from the documents
    chat_prompty = Prompty.load(
        f"{Path(__file__).parent.absolute().as_posix()}/chat.prompty",
        model={
            "configuration": model_config,
            "parameters": {"max_tokens": 256, "temperature": 0.2},
        },
    )
    result = chat_prompty(
        chat_history=chat_history, chat_input=chat_input, documents=documents
    )

    return {"reply": result, "context": documents}
