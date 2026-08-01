WITH sales_by_gender AS (
        SELECT
            cd.cd_gender AS gender,
            SUM(ws.ws_net_paid_inc_tax) AS amount,
            'sales' AS source
        FROM web_sales ws
        JOIN customer c
            ON ws.ws_bill_customer_sk = c.c_customer_sk
        JOIN customer_demographics cd
            ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
        WHERE ws.ws_net_paid_inc_tax > 1500
        GROUP BY cd.cd_gender
    ),
    returns_by_gender AS (
        SELECT
            cd.cd_gender AS gender,
            COALESCE(SUM(sr.sr_return_amt), 0) AS amount,
            'returns' AS source
        FROM store_returns sr
        RIGHT OUTER JOIN customer_demographics cd
            ON sr.sr_cdemo_sk = cd.cd_demo_sk
        GROUP BY cd.cd_gender
    )
SELECT gender,
       amount,
       source
FROM sales_by_gender
UNION ALL
SELECT gender,
       amount,
       source
FROM returns_by_gender
ORDER BY gender,
         source
