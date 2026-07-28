WITH sales_per_customer AS (
    SELECT
        ss_customer_sk,
        SUM(ss_net_paid) AS total_net_paid,
        SUM(ss_quantity) AS total_quantity,
        SUM(ss_ext_sales_price) AS total_ext_sales_price,
        COUNT(*) AS transaction_count
    FROM store_sales
    WHERE ss_ext_sales_price > 1000
      AND ss_quantity >= 2
      AND ss_net_profit > 0
      AND ss_list_price BETWEEN 10 AND 1000
    GROUP BY ss_customer_sk
)
SELECT
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    c.c_birth_country,
    s.total_net_paid,
    s.total_quantity,
    s.transaction_count,
    RANK() OVER (PARTITION BY c.c_birth_country ORDER BY s.total_net_paid DESC) AS rank_by_country,
    ROW_NUMBER() OVER (ORDER BY s.total_net_paid DESC) AS overall_rank
FROM customer c
JOIN sales_per_customer s
    ON s.ss_customer_sk = c.c_customer_sk
WHERE c.c_birth_country IN ('SURINAME', 'TURKMENISTAN')
  AND c.c_last_name LIKE 'B%'
LIMIT 100
