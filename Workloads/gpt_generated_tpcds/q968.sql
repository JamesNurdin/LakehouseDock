WITH store_sales_agg AS (
    SELECT
        c.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        ss.ss_net_paid AS net_paid
    FROM store_sales ss
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
),
catalog_sales_agg AS (
    SELECT
        c.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cs.cs_net_paid AS net_paid
    FROM catalog_sales cs
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
),
web_sales_agg AS (
    SELECT
        c.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        ws.ws_net_paid AS net_paid
    FROM web_sales ws
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
),
combined_sales AS (
    SELECT c_customer_sk, cd_gender, cd_marital_status, net_paid FROM store_sales_agg
    UNION ALL
    SELECT c_customer_sk, cd_gender, cd_marital_status, net_paid FROM catalog_sales_agg
    UNION ALL
    SELECT c_customer_sk, cd_gender, cd_marital_status, net_paid FROM web_sales_agg
)
SELECT
    cd_gender AS gender,
    cd_marital_status AS marital_status,
    SUM(net_paid) AS total_net_paid,
    COUNT(DISTINCT c_customer_sk) AS distinct_customers
FROM combined_sales
GROUP BY cd_gender, cd_marital_status
ORDER BY total_net_paid DESC
LIMIT 5
