FROM public.ecr.aws/lambda/python:3.13

WORKDIR ${LAMBDA_TASK_ROOT}

COPY src/anime_schedules/ .

CMD ["lambda_function.lambda_handler"]
