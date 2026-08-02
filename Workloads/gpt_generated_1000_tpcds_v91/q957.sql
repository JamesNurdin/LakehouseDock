WITH ss_agg AS (
    SELECT
        ss_customer_sk,
        ss_sold_date_sk,
        SUM(ss_ext_discount_amt) AS total_discount,
        SUM(ss_net_paid) AS total_net_paid,
        SUM(ss_net_profit) AS total_net_profit,
        COUNT(*) AS sales_cnt
    FROM store_sales
    WHERE ss_ext_discount_amt > 150.00
      AND ss_quantity >= 2
      AND ss_ext_sales_price > 1000.00
    GROUP BY ss_customer_sk, ss_sold_date_sk
),
non_preferred_customers AS (
    SELECT c.c_customer_sk
    FROM customer c
    EXCEPT
    SELECT c.c_customer_sk
    FROM customer c
    WHERE c.c_preferred_cust_flag = 'Y'
)
SELECT DISTINCT
    c.c_customer_id,
    ca.ca_state,
    d.d_year,
    d.d_month_seq,
    agg.total_net_paid,
    agg.total_net_profit,
    ROW_NUMBER() OVER (PARTITION BY ca.ca_state ORDER BY agg.total_net_paid DESC) AS state_customer_rank,
    CASE
        WHEN agg.total_discount > 5000 THEN 'High Discount'
        ELSE 'Normal Discount'
    END AS discount_category
FROM ss_agg agg
JOIN date_dim d
    ON agg.ss_sold_date_sk = d.d_date_sk
JOIN customer c
    ON agg.ss_customer_sk = c.c_customer_sk
JOIN customer_address ca
    ON c.c_current_addr_sk = ca.ca_address_sk
LEFT JOIN catalog_page cp
    ON (cp.cp_start_date_sk = d.d_date_sk OR cp.cp_end_date_sk = d.d_date_sk)
WHERE d.d_year = 1998
  AND d.d_holiday = 'N'
  AND c.c_birth_year BETWEEN 1950 AND 1975
  AND c.c_salutation = 'Mrs.'
  AND ca.ca_country = 'United States'
  AND agg.total_discount > 200
  AND c.c_customer_sk IN (SELECT c_customer_sk FROM non_preferred_customers)
  AND NOT EXISTS (
        SELECT 1
        FROM catalog_page cp2
        WHERE (cp2.cp_start_date_sk = d.d_date_sk OR cp2.cp_end_date_sk = d.d_date_sk)
          AND cp2.cp_type = 'Promotion'
          AND cp2.cp_description LIKE '%Holiday%'
    )
LIMIT 100
