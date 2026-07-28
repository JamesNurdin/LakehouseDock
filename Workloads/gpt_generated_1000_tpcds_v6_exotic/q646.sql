WITH billing AS (
    SELECT
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        SUM(cs.cs_net_profit) AS total_profit,
        COUNT(DISTINCT cs.cs_order_number) AS order_cnt
    FROM tpcds.catalog_sales cs
    JOIN tpcds.customer c
        ON cs.cs_bill_customer_sk = c.c_customer_sk
    WHERE cs.cs_ext_ship_cost > 500
      AND c.c_current_hdemo_sk = 4239
    GROUP BY c.c_customer_id, c.c_first_name, c.c_last_name
),
shipping AS (
    SELECT
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        SUM(cs.cs_net_profit) AS total_profit,
        COUNT(DISTINCT cs.cs_order_number) AS order_cnt
    FROM tpcds.catalog_sales cs
    JOIN tpcds.customer c
        ON cs.cs_ship_customer_sk = c.c_customer_sk
    WHERE cs.cs_sales_price BETWEEN 10 AND 100
      AND c.c_current_addr_sk = 5599388
    GROUP BY c.c_customer_id, c.c_first_name, c.c_last_name
)
SELECT
    c_customer_id,
    c_first_name,
    c_last_name,
    total_profit,
    order_cnt
FROM billing
UNION ALL
SELECT
    c_customer_id,
    c_first_name,
    c_last_name,
    total_profit,
    order_cnt
FROM shipping
ORDER BY total_profit DESC
LIMIT 20
