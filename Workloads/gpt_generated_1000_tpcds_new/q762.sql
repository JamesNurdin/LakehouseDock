WITH store_agg AS (
    SELECT
        d.d_year AS year,
        c.c_customer_id AS customer_id,
        SUM(ss.ss_net_paid) AS total_net_paid,
        COUNT(*) AS sales_count,
        (SELECT MAX(d2.d_year) FROM date_dim d2) AS max_year_global
    FROM store_sales ss
    TABLESAMPLE BERNOULLI (10)
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    WHERE EXISTS (
        SELECT 1 FROM store_returns sr
        WHERE sr.sr_ticket_number = ss.ss_ticket_number
    )
    GROUP BY CUBE(d.d_year, c.c_customer_id)
),
web_agg AS (
    SELECT
        d.d_year AS year,
        c.c_customer_id AS customer_id,
        SUM(ws.ws_net_paid) AS total_net_paid,
        COUNT(*) AS sales_count,
        (SELECT MAX(d2.d_year) FROM date_dim d2) AS max_year_global
    FROM web_sales ws
    TABLESAMPLE BERNOULLI (10)
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    WHERE EXISTS (
        SELECT 1 FROM web_returns wr
        WHERE wr.wr_order_number = ws.ws_order_number
    )
    GROUP BY CUBE(d.d_year, c.c_customer_id)
)
SELECT *
FROM store_agg
UNION ALL
SELECT *
FROM web_agg
LIMIT 100
