WITH store_channel AS (
    SELECT
        c.c_customer_id,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS customer_name,
        'store' AS sales_channel,
        SUM(ss.ss_net_profit) AS total_net_profit
    FROM store_sales ss
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    WHERE cd.cd_education_status = 'Advanced Degree'
    GROUP BY c.c_customer_id, c.c_first_name, c.c_last_name
),
web_channel AS (
    SELECT
        c.c_customer_id,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS customer_name,
        'web' AS sales_channel,
        SUM(ws.ws_net_profit) AS total_net_profit
    FROM web_sales ws
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
    WHERE cd.cd_education_status = 'Advanced Degree'
    GROUP BY c.c_customer_id, c.c_first_name, c.c_last_name
)
SELECT *
FROM store_channel
UNION ALL
SELECT *
FROM web_channel
ORDER BY total_net_profit DESC
LIMIT 100
