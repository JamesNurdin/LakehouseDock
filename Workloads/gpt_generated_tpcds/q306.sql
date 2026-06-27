-- Net profit by customer gender and marital status, combining store sales, web sales and web returns
WITH store_sales_demo AS (
    SELECT
        cd.cd_gender AS gender,
        cd.cd_marital_status AS marital_status,
        SUM(ss.ss_ext_sales_price) AS store_sales_amount,
        SUM(ss.ss_net_profit) AS store_net_profit
    FROM store_sales ss
    JOIN customer_demographics cd
        ON ss.ss_cdemo_sk = cd.cd_demo_sk
    GROUP BY cd.cd_gender, cd.cd_marital_status
),
web_sales_demo AS (
    SELECT
        cd.cd_gender AS gender,
        cd.cd_marital_status AS marital_status,
        SUM(ws.ws_ext_sales_price) AS web_sales_amount,
        SUM(ws.ws_net_profit) AS web_net_profit
    FROM web_sales ws
    JOIN customer_demographics cd
        ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
    GROUP BY cd.cd_gender, cd.cd_marital_status
),
web_returns_demo AS (
    SELECT
        cd.cd_gender AS gender,
        cd.cd_marital_status AS marital_status,
        SUM(wr.wr_return_amt) AS web_return_amount,
        SUM(wr.wr_net_loss) AS web_net_loss
    FROM web_returns wr
    JOIN web_sales ws
        ON wr.wr_item_sk = ws.ws_item_sk
        AND wr.wr_order_number = ws.ws_order_number
    JOIN customer_demographics cd
        ON wr.wr_refunded_cdemo_sk = cd.cd_demo_sk
    GROUP BY cd.cd_gender, cd.cd_marital_status
)
SELECT
    COALESCE(ss.gender, ws.gender, wr.gender) AS gender,
    COALESCE(ss.marital_status, ws.marital_status, wr.marital_status) AS marital_status,
    COALESCE(ss.store_sales_amount, 0) AS total_store_sales,
    COALESCE(ss.store_net_profit, 0) AS total_store_net_profit,
    COALESCE(ws.web_sales_amount, 0) AS total_web_sales,
    COALESCE(ws.web_net_profit, 0) AS total_web_net_profit,
    COALESCE(wr.web_return_amount, 0) AS total_web_returns,
    COALESCE(wr.web_net_loss, 0) AS total_web_net_loss,
    (COALESCE(ss.store_net_profit, 0) + COALESCE(ws.web_net_profit, 0) - COALESCE(wr.web_net_loss, 0)) AS overall_net_profit
FROM store_sales_demo ss
FULL OUTER JOIN web_sales_demo ws
    ON ss.gender = ws.gender
    AND ss.marital_status = ws.marital_status
FULL OUTER JOIN web_returns_demo wr
    ON COALESCE(ss.gender, ws.gender) = wr.gender
    AND COALESCE(ss.marital_status, ws.marital_status) = wr.marital_status
ORDER BY overall_net_profit DESC
LIMIT 20
