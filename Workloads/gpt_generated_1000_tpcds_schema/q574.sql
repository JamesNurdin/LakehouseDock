WITH ss_sample AS (
  SELECT *
  FROM store_sales
  TABLESAMPLE BERNOULLI (10)
),
store_agg AS (
  SELECT
    'store' AS src,
    i.i_item_id AS key_id,
    SUM(ss.ss_ext_sales_price) AS metric,
    RANK() OVER (PARTITION BY d.d_year ORDER BY SUM(ss.ss_ext_sales_price) DESC) AS rank_num,
    CAST(NULL AS varchar) AS extra
  FROM ss_sample ss
  JOIN item i ON ss.ss_item_sk = i.i_item_sk
  JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
  LEFT JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
  WHERE d.d_year = 2001
  GROUP BY i.i_item_id, d.d_year
  HAVING SUM(ss.ss_ext_sales_price) > 1000
),
cust_unnest AS (
  SELECT
    c.c_customer_id,
    ca.ca_address_id,
    ARRAY[c.c_email_address, c.c_first_name] AS info_arr,
    ib.ib_income_band_sk
  FROM customer c
  FULL OUTER JOIN customer_address ca
    ON c.c_current_addr_sk = ca.ca_address_sk
  LEFT JOIN household_demographics hd
    ON c.c_current_hdemo_sk = hd.hd_demo_sk
  LEFT JOIN income_band ib
    ON hd.hd_income_band_sk = ib.ib_income_band_sk
  WHERE c.c_customer_id IS NOT NULL OR ca.ca_address_id IS NOT NULL
),
cust_agg AS (
  SELECT
    'customer' AS src,
    ca_address_id AS key_id,
    COUNT(DISTINCT c_customer_id) AS metric,
    RANK() OVER (PARTITION BY ib_income_band_sk ORDER BY COUNT(DISTINCT c_customer_id) DESC) AS rank_num,
    info_elem AS extra
  FROM cust_unnest cu
  CROSS JOIN UNNEST(cu.info_arr) AS u(info_elem)
  GROUP BY ca_address_id, ib_income_band_sk, info_elem
  HAVING COUNT(DISTINCT c_customer_id) > 5
)
SELECT src, key_id, metric, rank_num, extra
FROM store_agg
UNION
SELECT src, key_id, metric, rank_num, extra
FROM cust_agg
LIMIT 100
