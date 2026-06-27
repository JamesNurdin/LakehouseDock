WITH catalog_sales_agg AS (
    SELECT
        cd.cd_gender,
        cd.cd_marital_status,
        SUM(cs.cs_net_paid_inc_tax) AS total_sales_net_paid,
        SUM(cs.cs_net_profit) AS total_sales_net_profit
    FROM catalog_sales cs
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    GROUP BY cd.cd_gender, cd.cd_marital_status
),
catalog_returns_agg AS (
    SELECT
        cd.cd_gender,
        cd.cd_marital_status,
        SUM(cr.cr_net_loss) AS total_returns_net_loss
    FROM catalog_returns cr
    JOIN catalog_sales cs ON cr.cr_order_number = cs.cs_order_number
                         AND cr.cr_item_sk = cs.cs_item_sk
    JOIN customer c ON cr.cr_refunded_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
    GROUP BY cd.cd_gender, cd.cd_marital_status
),
web_sales_agg AS (
    SELECT
        cd.cd_gender,
        cd.cd_marital_status,
        SUM(ws.ws_net_paid_inc_tax) AS total_web_net_paid,
        SUM(ws.ws_net_profit) AS total_web_net_profit
    FROM web_sales ws
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
    GROUP BY cd.cd_gender, cd.cd_marital_status
)
SELECT
    COALESCE(cs.cd_gender, wr.cd_gender, ws.cd_gender) AS gender,
    COALESCE(cs.cd_marital_status, wr.cd_marital_status, ws.cd_marital_status) AS marital_status,
    cs.total_sales_net_paid,
    cs.total_sales_net_profit,
    wr.total_returns_net_loss,
    ws.total_web_net_paid,
    ws.total_web_net_profit,
    (COALESCE(cs.total_sales_net_profit, 0) - COALESCE(wr.total_returns_net_loss, 0) + COALESCE(ws.total_web_net_profit, 0)) AS net_profit_after_returns
FROM catalog_sales_agg cs
FULL OUTER JOIN catalog_returns_agg wr
    ON cs.cd_gender = wr.cd_gender
   AND cs.cd_marital_status = wr.cd_marital_status
FULL OUTER JOIN web_sales_agg ws
    ON COALESCE(cs.cd_gender, wr.cd_gender) = ws.cd_gender
   AND COALESCE(cs.cd_marital_status, wr.cd_marital_status) = ws.cd_marital_status
ORDER BY gender, marital_status
