import boto3
import time
import paramiko
import os
import json
import argparse
import requests

# Load configuration based on the stage
def load_config(stage):
    with open(f"{stage}_config.json") as f:
        return json.load(f)

def create_ec2_instance(config):
    ec2 = boto3.resource('ec2', region_name=config['region'])

    instance = ec2.create_instances(
        ImageId=config['ami_id'],
        MinCount=1,
        MaxCount=1,
        InstanceType=config['instance_type'],
        KeyName=config['key_name'],
        SecurityGroupIds=[config['security_group']]  # corrected typo 'securiy_group'
    )[0]

    print("Waiting for instance to run...")
    instance.wait_until_running()
    instance.reload()
    print(f"Instance created with public IP: {instance.public_ip_address}")
    return instance

def ssh_and_deploy(instance, config):
    key = paramiko.RSAKey.from_private_key_file(config['ssh_key_path'])
    ssh = paramiko.SSHClient()
    ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    print("Connecting via SSH...")
    ssh.connect(hostname=instance.public_ip_address, username='ec2-user', pkey=key)

    commands = [
        'sudo yum update -y',
        'sudo yum install java-19-amazon-corretto -y',
        f'git clone {config["repo_url"]}',
        f'cd {config["repo_dir"]} && ./deploy.sh'
    ]

    for cmd in commands:
        print(f"Executing: {cmd}")
        stdin, stdout, stderr = ssh.exec_command(cmd)
        print(stdout.read().decode())
        print(stderr.read().decode())

    ssh.close()

def test_http(instance):
    try:
        print("Testing HTTP access...")
        response = requests.get(f"http://{instance.public_ip_address}", timeout=10)
        if response.status_code == 200:
            print("App is reachable on port 80.")
        else:
            print(f"App returned status code: {response.status_code}")
    except Exception as e:
        print(f"Failed to reach app: {e}")

def stop_instance(instance):
    print("Stopping instance...")
    instance.stop()
    instance.wait_until_stopped()
    print("Instance stopped.")

if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--stage", default="dev", help="Stage (dev/prod)")
    args = parser.parse_args()

    config = load_config(args.stage)
    instance = create_ec2_instance(config)
    time.sleep(60)  # wait for SSH to be available
    ssh_and_deploy(instance, config)
    test_http(instance)

    print("Waiting 1 minute before stopping instance...")
    time.sleep(60)
    stop_instance(instance)
