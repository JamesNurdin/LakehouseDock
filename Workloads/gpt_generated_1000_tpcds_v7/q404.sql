WITH preferred_customers AS (
    SELECT
        c.c_customer_id AS customer_id,
        dd.d_date AS event_date,
        ws.web_name AS website_name,
        'Preferred' AS customer_type
    FROM
        tpcds.customer c
        JOIN tpcds.date_dim dd ON c.c_first_shipto_date_sk = dd.d_date_sk
        JOIN tpcds.web_site ws ON ws.web_open_date_sk = dd.d_date_sk
    WHERE
        c.c_preferred_cust_flag = 'Y'
        AND dd.d_year = 2022
        AND ws.web_city = 'Lakewood'
),
regular_customers AS (
    SELECT
        c.c_customer_id AS customer_id,
        dd.d_date AS event_date,
        ws.web_name AS website_name,
        'Regular' AS customer_type
    FROM
        tpcds.customer c
        JOIN tpcds.date_dim dd ON c.c_first_sales_date_sk = dd.d_date_sk
        JOIN tpcds.web_site ws ON ws.web_close_date_sk = dd.d_date_sk
    WHERE
        c.c_preferred_cust_flag = 'N'
        AND dd.d_year = 2021
        AND ws.web_city = 'Harmony'
)
SELECT * FROM preferred_customers
UNION ALL
SELECT * FROM regular_customers
LIMIT 100
