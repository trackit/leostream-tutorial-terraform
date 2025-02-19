# Leostream Infrastructure - Root Module

This is the root module for setting up a Leostream environment in AWS using Terraform. It orchestrates the deployment of various components including networking, Active Directory, Leostream services, and workstation management.

## Prerequisites

- Terraform installed on your machine.
- AWS CLI configured with appropriate permissions to create resources in your AWS account.

## Structure

- **Network**: Manages VPC, subnets, internet gateways, NAT, and routing.
- **Active Directory**: Configures AWS Managed Microsoft AD for domain services.
- **Leostream**: Sets up Leostream Broker and Gateway for remote management.
- **Workstation**: Manages launch templates and configurations for workstations.

## Modules

### Network
- **Source**: `./modules/network`
- **Description**: Creates the VPC, subnets, and necessary routing for our infrastructure.

### Active Directory
- **Source**: `./modules/active_directory`
- **Description**: Deploys AWS Managed Microsoft AD for centralized identity management.

### Leostream
- **Source**: `./modules/leostream`
- **Description**: Installs Leostream Broker and Gateway for managing remote desktops.

### Workstation
- **Source**: `./modules/workstation`
- **Description**: Manages workstation instances through launch templates.

## Usage

To use this root module:

```bash
cd /path/to/your/terraform/project
terraform init
terraform plan
terraform apply
```

## Workstation AMI Requirements

Before deploying or using the workstations in this Leostream setup, ensure your AMI (Amazon Machine Image) includes the following software and configurations:

### Essential Software:

- **Windows Server Operating System**: Preferably the latest version supported by AWS and Leostream for optimal performance and security.

- **NICE DCV Agent**:
  - **Installation**: The DCV Agent should be installed for remote desktop capabilities. You can download it from the [NICE DCV website](https://download.nice-dcv.com).
  - **Version**: Ensure the version matches or is compatible with the Leostream Gateway setup.

- **Leostream Agent**:
  - **Installation**: 
    - Install the Leostream Agent to enable management, policy enforcement, and integration with the Leostream Broker. Download the agent from the Leostream Management Console.
    - **Note**: Install the agent without specifying the Broker address during the initial setup. This will be configured post-deployment to ensure flexibility across different environments.

- **AWS Systems Manager (SSM) Agent**:
  - **Installation**: The SSM Agent should be pre-installed or installed during the first boot for instance management without public IPs.
  - **Service Status**: Ensure the service is set to start automatically on boot.

- **NVIDIA GRID Drivers**:
  - **Installation**: Install NVIDIA GRID drivers since most workstations will be running on instance types like G4dn, G5, etc., which are equipped with NVIDIA GPUs. 
    - **Driver Version**: Choose a driver version compatible with both your AWS instance type and the NVIDIA GRID software you're using (e.g., for virtual GPU support).
    - **Licensing**: Ensure you have the appropriate licensing for NVIDIA GRID if required.
    - **Download**: Drivers can be downloaded from the [NVIDIA website](https://www.nvidia.com/Download/index.aspx) or through AWS EC2 instance type-specific recommendations.
  - **Verification**: After installation, verify the drivers are functioning correctly by checking the device manager or running a GPU benchmark.

### Additional Configurations:

- **User Accounts**:
  - **AMI Preparation**: Do not join the workstation to an Active Directory domain during AMI preparation. This step should be performed post-deployment within the studio network to avoid any dependency on specific network configurations or AD settings during AMI creation.

### AMI Creation:

If you're creating your own AMI:

- Use AWS EC2 Image Builder software, uncheck public ip from wallpaper tab and select "shutdown with sysprep".