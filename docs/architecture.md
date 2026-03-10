# Architecture Diagram

```mermaid
flowchart LR
  subgraph Connect["Amazon Connect"]
    Phone["Claimed Phone Number"]
    Flow["Contact Flow"]
  end

  subgraph Compute["AWS Lambda Services"]
    Vanity["connect-contact Lambda"]
    PublicApi["public-api Lambda"]
  end

  subgraph Data["Data Layer"]
    DDB[("DynamoDB: connect-vanity-calls")]
  end

  subgraph Api["Shared API"]
    APIGW["HTTP API Gateway"]
  end

  subgraph Web["Bonus Web Hosting"]
    CF["CloudFront"]
    S3["S3 Static Site + runtime-config.json"]
    Browser["Web App"]
  end

  Phone --> Flow
  Flow --> Vanity
  Vanity --> DDB
  Flow --> Phone

  APIGW --> PublicApi
  PublicApi --> DDB

  Browser --> CF
  CF --> S3
  Browser --> APIGW
```

## Runtime Sequence

1. Caller dials Connect number.
2. Contact flow invokes `connect-contact` Lambda.
3. Lambda generates top vanity options and stores call record in DynamoDB.
4. Flow speaks top 3 vanity options back to caller.
5. Web app reads API URL from `runtime-config.json` and calls API Gateway.
6. `public-api` Lambda returns latest callers from DynamoDB.
