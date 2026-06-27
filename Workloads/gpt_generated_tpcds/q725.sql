WITH sales_by_demo AS (
    SELECT
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        SUM(ws.ws_net_profit) AS total_profit,
        COUNT(DISTINCT ws.ws_order_number) AS num_orders
    FROM web_sales ws
    JOIN customer c
        ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd
        ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
    GROUP BY cd.cd_demo_sk, cd.cd_gender, cd.cd_marital_status
),
returns_by_demo AS (
    SELECT
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        SUM(sr.sr_return_amt) AS total_returns,
        SUM(sr.sr_net_loss) AS total_net_loss,
        COUNT(*) AS num_returns
    FROM store_returns sr
    JOIN customer c
        ON sr.sr_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd
        ON sr.sr_cdemo_sk = cd.cd_demo_sk
    GROUP BY cd.cd_demo_sk, cd.cd_gender, cd.cd_marital_status
)
SELECT
    s.cd_gender,
    s.cd_marital_status,
    s.total_sales,
    r.total_returns,
    s.total_profit,
    r.total_net_loss,
    (s.total_sales - COALESCE(r.total_returns, 0)) AS net_sales_minus_returns,
    (s.total_profit - COALESCE(r.total_net_loss, 0)) AS net_profit_minus_loss,
    s.num_orders,
    r.num_returns
FROM sales_by_demo s
LEFT JOIN returns_by_demo r
    ON s.cd_demo_sk = r.cd_demo_sk
ORDER BY s.total_sales DESC
LIMIT 20
