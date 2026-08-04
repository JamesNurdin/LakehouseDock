WITH sampled_sales AS (
    SELECT *
    FROM store_sales
    TABLESAMPLE BERNOULLI (10)
),
joined_data AS (
    SELECT
        c.c_customer_id,
        ca.ca_state,
        ss.ss_sold_date_sk,
        ss.ss_quantity,
        ss.ss_net_paid,
        ss.ss_ext_sales_price,
        ss.ss_ext_discount_amt,
        ss.ss_coupon_amt,
        ARRAY[ss.ss_quantity, ss.ss_net_paid] AS qty_paid_arr
    FROM sampled_sales ss
    JOIN customer c
        ON ss.ss_customer_sk = c.c_customer_sk
    JOIN customer_address ca
        ON ss.ss_addr_sk = ca.ca_address_sk
    WHERE ca.ca_gmt_offset = -5.00
      AND c.c_birth_year BETWEEN 1960 AND 1970
      AND ss.ss_ext_sales_price > 1000
      AND ss.ss_coupon_amt = 0.00
),
unnested AS (
    SELECT
        jd.c_customer_id,
        jd.ca_state,
        jd.ss_sold_date_sk,
        jd.ss_quantity,
        jd.ss_net_paid,
        jd.ss_ext_sales_price,
        jd.ss_ext_discount_amt,
        jd.ss_coupon_amt,
        v AS measure_value,
        CASE
            WHEN jd.ss_ext_discount_amt > 500 THEN 'HIGH_DISCOUNT'
            ELSE 'LOW_DISCOUNT'
        END AS discount_category
    FROM joined_data jd
    CROSS JOIN UNNEST(jd.qty_paid_arr) AS t(v)
)
SELECT
    ca_state,
    CASE
        WHEN AVG(ss_ext_sales_price) > 2000 THEN 'BIG_SPENDER'
        ELSE 'NORMAL_SPENDER'
    END AS spender_category,
    COUNT(DISTINCT c_customer_id) AS unique_customers,
    SUM(ss_ext_sales_price) AS total_sales,
    AVG(ss_ext_discount_amt) AS avg_discount,
    MIN(measure_value) AS min_measure,
    MAX(measure_value) AS max_measure,
    (SELECT AVG(ss_ext_sales_price) FROM store_sales) AS overall_avg_sales
FROM unnested
GROUP BY GROUPING SETS (
    (ca_state, discount_category),
    (ca_state),
    ()
)
ORDER BY total_sales DESC
LIMIT 100
