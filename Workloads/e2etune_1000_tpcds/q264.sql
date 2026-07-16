WITH cust_sales AS (
    SELECT
        c.c_customer_sk,
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        c.c_birth_month,
        c.c_birth_year,
        SUM(ss.ss_net_paid) AS total_net_paid,
        SUM(ss.ss_net_profit) AS total_net_profit,
        SUM(ss.ss_ext_discount_amt) AS total_discount,
        SUM(ss.ss_quantity) AS total_quantity,
        COUNT(*) AS sales_cnt,
        AVG(ss.ss_sales_price) AS avg_sales_price,
        MIN(ss.ss_sold_date_sk) AS first_sale_date_sk,
        MAX(ss.ss_sold_date_sk) AS last_sale_date_sk
    FROM store_sales ss
    JOIN customer c
        ON ss.ss_customer_sk = c.c_customer_sk
    WHERE c.c_birth_month IN (4, 12, 2)
      AND c.c_email_address LIKE '%@%edu'
    GROUP BY
        c.c_customer_sk,
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        c.c_birth_month,
        c.c_birth_year
    HAVING SUM(ss.ss_net_profit) > 500
)
SELECT
    cs.c_customer_id,
    cs.c_first_name,
    cs.c_last_name,
    cs.c_birth_month,
    cs.c_birth_year,
    cs.total_net_paid,
    cs.total_net_profit,
    cs.total_discount,
    cs.total_quantity,
    cs.sales_cnt,
    cs.avg_sales_price,
    cs.total_net_profit / NULLIF(cs.total_net_paid, 0) AS profit_margin,
    RANK() OVER (ORDER BY cs.total_net_profit DESC) AS profit_rank
FROM cust_sales cs
ORDER BY profit_rank
LIMIT 50
