import argparse
import os
import pandas as pd
from tabulate import tabulate

from promptflow.core import AzureOpenAIModelConfiguration
from promptflow.evals.evaluate import evaluate
from promptflow.evals.evaluators import (
    CoherenceEvaluator,
    F1ScoreEvaluator,
    FluencyEvaluator,
    GroundednessEvaluator,
    RelevanceEvaluator,
    SimilarityEvaluator,
    QAEvaluator,
)
from azure.ai.ml import MLClient
from azure.identity import DefaultAzureCredential

from sqd_flow.sqd_azure import get_chat_response

from dotenv import load_dotenv

load_dotenv()
def calculate_percentage(metric_value):
    """Convert a metric score to a percentage."""
    if isinstance(metric_value, (int, float)):
        return (metric_value * 100)/5  # Convert to percentage with 2 decimal places
    else:
        raise ValueError("Metric value must be a number")

def display_metrics_with_percentages(metrics):
    """Display metric values and their corresponding percentages."""
    for metric_name, metric_value in metrics.items():
        percentage = calculate_percentage(metric_value)
        print(f"{metric_name}: {percentage}%")
    return percentage
        
# Initialize MLClient
client = MLClient(
    DefaultAzureCredential(),
    os.getenv("AZURE_SUBSCRIPTION_ID"),
    os.getenv("AZURE_RESOURCE_GROUP"),
    os.getenv("AZUREAI_PROJECT_NAME"),
)
azure_ai_project = {
    "subscription_id": os.getenv("AZURE_SUBSCRIPTION_ID"),
    "resource_group_name": os.getenv("AZURE_RESOURCE_GROUP"),
    "project_name": os.getenv("AZUREAI_PROJECT_NAME"),
}

os.environ['AZURE_OPENAI_API_KEY'] = client.connections.get(os.getenv("AZURE_OPENAI_CONNECTION_NAME"), populate_secrets=True).api_key
os.environ['AZURE_SEARCH_API_KEY'] = client.connections.get(os.getenv("AZURE_SEARCH_CONNECTION_NAME"), populate_secrets=True).api_key
os.environ['AZURE_SEARCH_ENDPOINT'] = client.connections.get(os.getenv("AZURE_SEARCH_CONNECTION_NAME")).api_base
os.environ['AZURE_OPENAI_ENDPOINT'] = client.connections.get(os.getenv("AZURE_OPENAI_CONNECTION_NAME")).api_base


def get_model_config(evaluation_endpoint, evaluation_model):
    """Get the model configuration for the evaluation."""
    if "AZURE_OPENAI_API_KEY" in os.environ:
        api_key = client.connections.get(os.getenv("AZURE_OPENAI_CONNECTION_NAME"), populate_secrets=True).api_key
        
        model_config = AzureOpenAIModelConfiguration(
            azure_endpoint=evaluation_endpoint,
            api_key=api_key,
            azure_deployment=evaluation_model,
        )
    else:
        model_config = AzureOpenAIModelConfiguration(
            azure_endpoint=evaluation_endpoint,
            azure_deployment=evaluation_model,
        )

    return model_config

def run_evaluation(
    evaluation_name,
    evaluation_model_config,
    evaluation_data_path,
    metrics,
    output_path=None,
):
    """Run the evaluation routine."""
    completion_func = get_chat_response

    evaluators = {}
    evaluators_config = {}
    for metric_name in metrics:
        if metric_name == "coherence":
            evaluators[metric_name] = CoherenceEvaluator(evaluation_model_config)
            evaluators_config[metric_name] = {
                "question": "${data.chat_input}",
                "answer": "${target.reply}",
            }
        elif metric_name == "f1score":
            evaluators[metric_name] = F1ScoreEvaluator()
            evaluators_config[metric_name] = {
                "answer": "${target.reply}",
                "ground_truth": "${data.ground_truth}",
            }
        elif metric_name == "fluency":
            evaluators[metric_name] = FluencyEvaluator(evaluation_model_config)
            evaluators_config[metric_name] = {
                "question": "${data.chat_input}",
                "answer": "${target.reply}",
            }
        elif metric_name == "groundedness":
            evaluators[metric_name] = GroundednessEvaluator(evaluation_model_config)
            evaluators_config[metric_name] = {
                "answer": "${target.reply}",
                "context": "${target.context}",
            }
        elif metric_name == "relevance":
            evaluators[metric_name] = RelevanceEvaluator(evaluation_model_config)
            evaluators_config[metric_name] = {
                "question": "${data.chat_input}",
                "answer": "${target.reply}",
                "context": "${target.context}",
            }
        elif metric_name == "similarity":
            evaluators[metric_name] = SimilarityEvaluator(evaluation_model_config)
            evaluators_config[metric_name] = {
                "question": "${data.chat_input}",
                "answer": "${target.reply}",
                "ground_truth": "${data.ground_truth}",
            }
        elif metric_name == "qa":
            evaluators[metric_name] = QAEvaluator(evaluation_model_config)
            evaluators_config[metric_name] = {
                "question": "${data.chat_input}",
                "answer": "${target.reply}",
                "context": "${target.context}",
                "ground_truth": "${data.ground_truth}",
            }
        elif metric_name == "latency":
            raise NotImplementedError("Latency metric is not implemented yet")
        else:
            raise ValueError(f"Unknown metric: {metric_name}")

    result = evaluate(
        target=completion_func,
        evaluation_name=evaluation_name,
        evaluators=evaluators,
        evaluator_config=evaluators_config,
        data=evaluation_data_path,
        azure_ai_project=azure_ai_project,
    )

    tabular_result = pd.DataFrame(result.get("rows"))
    return result, tabular_result

def main():
    """Run the evaluation script."""
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--evaluation-data-path",
        help="Path to JSONL file containing evaluation dataset",
        required=True,
    )
    parser.add_argument(
        "--evaluation-name",
        help="Evaluation name used to log the evaluation to AI Studio",
        type=str,
        default="eval-sdk-dev",
    )
    parser.add_argument(
        "--evaluation-endpoint",
        help="Azure OpenAI endpoint used for evaluation",
        type=str,
        default=client.connections.get(os.getenv("AZURE_OPENAI_CONNECTION_NAME")).api_base,
    )
    parser.add_argument(
        "--evaluation-model",
        help="Azure OpenAI model deployment name used for evaluation",
        type=str,
        default=os.getenv("AZURE_OPENAI_EVALUATION_DEPLOYMENT"),
    )
    parser.add_argument(
        "--metrics",
        nargs="+",
        help="List of metrics to evaluate",
        choices=[
            "coherence",
            "f1score",
            "fluency",
            "groundedness",
            "relevance",
            "similarity",
            "qa",
            "chat",
            "latency",
        ],
        required=True,
    )
    args = parser.parse_args()

    eval_model_config = get_model_config(
        args.evaluation_endpoint, args.evaluation_model
    )

    result, tabular_result = run_evaluation(
        evaluation_name=args.evaluation_name,
        evaluation_model_config=eval_model_config,
        evaluation_data_path=args.evaluation_data_path,
        metrics=args.metrics,
    )
    # Extract and display metrics with percentages
    print("-----Summarized Metrics-----")
    percentage = display_metrics_with_percentages(result["metrics"])
    print("The final Percentage is: ", percentage)
    print(f"View evaluation results in AI Studio: {result['studio_url']}")
    if percentage < 90:
        print("Not all metrics are above 90%. Please review the results.")
        exit(1)
    
if __name__ == "__main__":
    main()
