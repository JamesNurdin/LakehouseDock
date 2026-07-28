WITH filtered_dates AS (
    SELECT d_date_sk, d_year
    FROM tpcds.date_dim
    WHERE d_year BETWEEN 2000 AND 2001
)
SELECT sales_channel,
       customer_id,
       sales_year,
       total_net_paid,
       profit_category
FROM (
    SELECT
        'catalog' AS sales_channel,
        c.c_customer_id AS customer_id,
        dd.d_year AS sales_year,
        SUM(cs.cs_net_paid) AS total_net_paid,
        CASE
            WHEN SUM(cs.cs_net_profit) > 10000 THEN 'high'
            WHEN SUM(cs.cs_net_profit) > 0    THEN 'medium'
            ELSE 'low'
        END AS profit_category
    FROM tpcds.catalog_sales cs
    JOIN filtered_dates dd
        ON cs.cs_sold_date_sk = dd.d_date_sk
    JOIN tpcds.customer c
        ON cs.cs_bill_customer_sk = c.c_customer_sk
    WHERE cs.cs_quantity > 0
      AND EXISTS (
            SELECT 1
            FROM tpcds.catalog_returns cr
            WHERE cr.cr_order_number = cs.cs_order_number
              AND cr.cr_return_quantity > 0
        )
    GROUP BY c.c_customer_id, dd.d_year

    UNION ALL

    SELECT
        'web' AS sales_channel,
        c.c_customer_id AS customer_id,
        dd.d_year AS sales_year,
        SUM(ws.ws_net_paid) AS total_net_paid,
        CASE
            WHEN SUM(ws.ws_net_profit) > 8000 THEN 'high'
            WHEN SUM(ws.ws_net_profit) > 0    THEN 'medium'
            ELSE 'low'
        END AS profit_category
    FROM tpcds.web_sales ws
    JOIN filtered_dates dd
        ON ws.ws_sold_date_sk = dd.d_date_sk
    JOIN tpcds.customer c
        ON ws.ws_bill_customer_sk = c.c_customer_sk
    WHERE ws.ws_quantity > 0
      AND EXISTS (
            SELECT 1
            FROM tpcds.web_returns wr
            WHERE wr.wr_order_number = ws.ws_order_number
              AND wr.wr_return_quantity > 0
        )
    GROUP BY c.c_customer_id, dd.d_year
) AS combined
ORDER BY total_net_paid DESC
LIMIT 100
