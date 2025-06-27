docker run --rm -v "$PWD":/var/task --entrypoint bash public.ecr.aws/lambda/python:3.9 -c "\
  yum install -y zip > /dev/null && \
  pip install pillow -t /var/task/package && \
  cd /var/task/package && \
  zip -r /var/task/lambda_function.zip . > /dev/null && \
  cd /var/task && \
  zip -g lambda_function.zip lambda_function.py" \
  "rm -rf /var/task/package && \
  echo 'Lambda function zip created successfully.'"