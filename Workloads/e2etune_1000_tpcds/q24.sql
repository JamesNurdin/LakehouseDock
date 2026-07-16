WITH sales_by_customer AS (
    SELECT
        ss_customer_sk,
        SUM(ss_ext_sales_price) AS total_sales,
        SUM(ss_net_profit) AS total_profit,
        SUM(ss_ext_discount_amt) AS total_discount,
        SUM(ss_quantity) AS total_quantity,
        COUNT(*) AS transaction_cnt,
        MIN(ss_sold_date_sk) AS first_sale_date,
        MAX(ss_sold_date_sk) AS last_sale_date
    FROM store_sales
    WHERE ss_sold_date_sk BETWEEN 2450000 AND 2452000
    GROUP BY ss_customer_sk
),
customer_enriched AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        c.c_email_address,
        c.c_preferred_cust_flag,
        c.c_birth_day,
        c.c_birth_month,
        c.c_birth_year,
        c.c_salutation,
        s.total_sales,
        s.total_profit,
        s.total_discount,
        s.total_quantity,
        s.transaction_cnt,
        s.first_sale_date,
        s.last_sale_date
    FROM customer c
    LEFT JOIN sales_by_customer s
        ON c.c_customer_sk = s.ss_customer_sk
    WHERE c.c_preferred_cust_flag = 'Y'
      AND c.c_email_address LIKE '%@%.org'
)
SELECT
    c.c_salutation,
    c.c_first_name,
    c.c_last_name,
    c.c_birth_month,
    c.c_birth_year,
    c.total_sales,
    c.total_profit,
    c.total_quantity,
    c.transaction_cnt,
    ROUND(c.total_discount / NULLIF(c.total_sales, 0) * 100, 2) AS discount_pct,
    ROUND(c.total_profit / NULLIF(c.total_sales, 0) * 100, 2) AS profit_margin_pct,
    RANK() OVER (PARTITION BY c.c_birth_month ORDER BY c.total_profit DESC) AS profit_rank_within_birth_month
FROM customer_enriched c
WHERE c.total_sales IS NOT NULL
ORDER BY c.c_birth_month, profit_rank_within_birth_month
LIMIT 100
