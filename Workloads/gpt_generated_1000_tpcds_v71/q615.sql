WITH store_agg AS (
    SELECT
        ss.ss_item_sk AS item_sk,
        ss.ss_customer_sk AS customer_sk,
        cd.cd_gender AS gender,
        SUM(ss.ss_net_paid) AS total_net_paid,
        d.d_year AS year
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    WHERE d.d_year = 2001
    GROUP BY ss.ss_item_sk, ss.ss_customer_sk, cd.cd_gender, d.d_year
    HAVING SUM(ss.ss_net_paid) > 1000
)
SELECT DISTINCT *
FROM (
    SELECT
        item_sk,
        customer_sk,
        gender,
        total_net_paid,
        year,
        'store' AS channel
    FROM store_agg
    UNION ALL
    SELECT
        ws.ws_item_sk AS item_sk,
        ws.ws_bill_customer_sk AS customer_sk,
        cd2.cd_gender AS gender,
        SUM(ws.ws_net_paid) AS total_net_paid,
        d2.d_year AS year,
        'web' AS channel
    FROM web_sales ws
    JOIN date_dim d2 ON ws.ws_sold_date_sk = d2.d_date_sk
    JOIN customer c2 ON ws.ws_bill_customer_sk = c2.c_customer_sk
    JOIN customer_demographics cd2 ON ws.ws_bill_cdemo_sk = cd2.cd_demo_sk
    WHERE d2.d_year = 2001
    GROUP BY ws.ws_item_sk, ws.ws_bill_customer_sk, cd2.cd_gender, d2.d_year
    HAVING SUM(ws.ws_net_paid) > 1000
) AS combined
LIMIT 100
