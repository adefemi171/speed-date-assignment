# Cloudformation assignment

Welcome to the Cloudformation assignment. In this assignment we kindly ask you to add additional security features to an existing cloudformation stack.
To be independent of any AWS accounts, we've prepared a docker-compose configuration that will start the [localstack](https://github.com/localstack) AWS cloud stack on your machine. 

Please see the usage section on how to authenticate.

# Assignment

The current, basic cloudformation template doesn't contain any additional security featuress/configurations. Please have a look at the cfn-nag report. There are a couple of findings which have to be fixed. Please extend the cloudformation template accordingly.

# Usage

## Start localstack

```shell
docker-compose up
```

Watch the logs for `Execution of "preload_services" took 986.95ms`

## Authentication
```shell
export AWS_ACCESS_KEY_ID=foobar
export AWS_SECRET_ACCESS_KEY=foobar
export AWS_REGION=eu-central-1

export AWS_ACCESS_KEY_ID=AKIAYHK4YT7POUF3YOFZ
export AWS_SECRET_ACCESS_KEY=6Nn566xQTjVTErRGVUfIn76ZLZMEQhEV7grKU1Vs
export AWS_REGION=eu-west-3
```

## AWS CLI examples
### S3
```shell
aws --endpoint-url http://localhost:4566 s3api list-buckets
```

## Create Stack
```shell
aws --endpoint-url http://localhost:4566 cloudformation create-stack --stack-name <STACK_NAME> --template-body file://stack.template --parameters ParameterKey=BucketName,ParameterValue=<BUCKET_NAME>
```

## CFN-NAG Report
### Show last report
```shell
docker logs cfn-nag
```
### Recreate report
```shell
docker-compose restart cfn-nag
```