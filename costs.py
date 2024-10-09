import re
import requests
from dotenv import load_dotenv
import os
import subprocess
import json

# Load environment variables from .env file
load_dotenv()

def fetch_price(currency):
    try:
        url = f"https://api.coingecko.com/api/v3/simple/price?ids={currency}&vs_currencies=usd"
        response = requests.get(url)
        data = response.json()
        return data[currency]['usd']
    except:
        if currency == "ethereum":
            return 2300
        elif currency == "optimism":
            return 1.5

def fetch_eth_gas_price():
    try:
        api_key = os.getenv("ETHERSCAN_API_KEY")
        url = f"https://api.etherscan.io/api?module=gastracker&action=gasoracle&apikey={api_key}"
        response = requests.get(url)
        data = response.json()
        return float(data['result']['SafeGasPrice'])
    except:
        return 3

def calculate_execution_costs(amount, eth_price, opt_price, eth_gas_price, opt_gas_price):
    eth_gas_price_eth = eth_gas_price * 1e-9
    opt_gas_price_eth = opt_gas_price * 1e-9

    # Calculate the total cost in ETH for both Ethereum and Optimism
    total_cost_eth_eth = amount * eth_gas_price_eth
    total_cost_opt_eth = amount * opt_gas_price_eth

    # Calculate the total cost in USD for both Ethereum and Optimism
    total_cost_eth_usd = total_cost_eth_eth * eth_price
    total_cost_opt_usd = total_cost_opt_eth * opt_price

    return total_cost_eth_eth, total_cost_eth_usd, total_cost_opt_eth, total_cost_opt_usd

def run_tests():
    command = "forge test --gas-report"
    result = subprocess.run(command, shell=True, capture_output=True, text=True)
    
    with open("gas-report.json", "w") as file:
        file.write(result.stdout)
    
    return result.stdout

def extract_and_calculate(stdout, eth_price, opt_price, eth_gas_price, opt_gas_price):
    pattern = re.compile(r'\|\s+(\w+)\s+\|.*?\|\s+(\d+)\s+\|.*?\|\s+(\d+)\s+\|')
    matches = pattern.findall(stdout)
    
    results = []
    for match in matches:
        function_name, min_cost, avg_cost = match
        avg_cost = int(avg_cost)
        total_cost_eth_eth, total_cost_eth_usd, total_cost_opt_eth, total_cost_opt_usd = calculate_execution_costs(
            avg_cost, eth_price, opt_price, eth_gas_price, opt_gas_price
        )
        results.append({
            "function_name": function_name,
            "amount": avg_cost,
            "total_cost_eth_eth": f"{total_cost_eth_eth:.8f}",
            "total_cost_eth_usd": f"{total_cost_eth_usd:.8f}",
            "total_cost_opt_eth": f"{total_cost_opt_eth:.8f}",
            "total_cost_opt_usd": f"{total_cost_opt_usd:.8f}"
        })
    
    with open("calculated_costs.json", "w") as file:
        json.dump(results, file, indent=4)

def main():
    eth_price = fetch_price("ethereum")
    opt_price = fetch_price("optimism")
    eth_gas_price = fetch_eth_gas_price()
    opt_gas_price = 0.1 * eth_gas_price

    stdout = run_tests()
    extract_and_calculate(stdout, eth_price, opt_price, eth_gas_price, opt_gas_price)

if __name__ == "__main__":
    main()