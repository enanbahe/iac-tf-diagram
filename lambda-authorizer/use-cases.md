# Lambda AuthZ + backend

Option A: Browser >> xyz.toyota.com >> CloudFront >> API-GW >> Lambda-AuthZ >> Fargate Container
Option B: Browser >> xyz.toyota.com >> API-GW >> Lambda-AuthZ >> Fargate Container
Option C: Browser >> xyz.toyota.com >> CloudFront >> API-GW >> Lambda-AuthZ >> API-GW
Option D: Browser >> xyz.toyota.com >> API-GW >> Lambda-AuthZ >> API-GW

* As a User, I want to be able to use custom domain name with ACM-managed SSL certificate
* As a Security Engineer, I want access logs to be saved to S3
* As a User, I want requests to be forwarded to load-balancer (Fargate containers) or API Gateway Endpoint after successful authentication
* As a User, I want to be able to use multiple destination endpoints for different requests/methods
* As a User, I want to be able to forward requests to endpoints in private subnet via PrivateLink

# Lambda AuthZ
* As a User, I want to be able to deploy Lambda AuthZ in front of my application
* As a User, I want to be able to configure token properties according to my NFR
* As a User, I do not want to configure Lambda AuthZ service NFRs (lambda throttling, DynamoDB performance)
* As a User, I do not want to have manual provisioning steps or external dependencies for Lambda AuthZ service

