WITH bill_sales AS (
    SELECT
        c.c_customer_sk,
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        SUM(cs.cs_ext_sales_price) AS total_sales_amount,
        SUM(cs.cs_net_profit) AS total_profit,
        SUM(cs.cs_quantity) AS total_quantity,
        AVG(cs.cs_ext_discount_amt) AS avg_discount
    FROM catalog_sales cs
    JOIN customer c
        ON cs.cs_bill_customer_sk = c.c_customer_sk
    GROUP BY
        c.c_customer_sk,
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name
),
ship_sales AS (
    SELECT
        c.c_customer_sk,
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        SUM(cs.cs_ext_sales_price) AS total_ship_sales_amount,
        SUM(cs.cs_net_profit) AS total_ship_profit,
        SUM(cs.cs_quantity) AS total_ship_quantity,
        AVG(cs.cs_ext_discount_amt) AS avg_ship_discount
    FROM catalog_sales cs
    JOIN customer c
        ON cs.cs_ship_customer_sk = c.c_customer_sk
    GROUP BY
        c.c_customer_sk,
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name
)
SELECT
    b.c_customer_sk,
    b.c_customer_id,
    b.c_first_name,
    b.c_last_name,
    b.total_sales_amount,
    b.total_profit,
    b.total_quantity,
    b.avg_discount,
    s.total_ship_sales_amount,
    s.total_ship_profit,
    s.total_ship_quantity,
    s.avg_ship_discount,
    (b.total_sales_amount + s.total_ship_sales_amount) AS total_combined_sales,
    (b.total_profit + s.total_ship_profit) AS total_combined_profit
FROM bill_sales b
FULL OUTER JOIN ship_sales s
    ON b.c_customer_sk = s.c_customer_sk
ORDER BY total_combined_sales DESC
LIMIT 100
