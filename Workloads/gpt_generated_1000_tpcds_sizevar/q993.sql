WITH base_agg AS (
  SELECT
    sr.sr_store_sk,
    sr.sr_customer_sk,
    sr.sr_item_sk,
    c.c_first_shipto_date_sk,
    i.i_category,
    s.s_market_desc,
    SUM(sr.sr_return_amt_inc_tax) AS total_return_inc_tax,
    COUNT(*) AS cnt_returns
  FROM store_returns sr
  JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
  JOIN item i ON sr.sr_item_sk = i.i_item_sk
  JOIN store s ON sr.sr_store_sk = s.s_store_sk
  WHERE c.c_birth_day BETWEEN 1 AND 28                               -- predicate 1
    AND c.c_birth_month IN (1,2,3,4,5,6)                            -- predicate 2
    AND c.c_first_sales_date_sk > 2450000                          -- predicate 3
    AND i.i_current_price > 20                                     -- predicate 4
    AND s.s_tax_percentage < 5                                     -- predicate 5
    AND sr.sr_reason_sk NOT IN (20,61)                             -- predicate 6
  GROUP BY
    sr.sr_store_sk,
    sr.sr_customer_sk,
    sr.sr_item_sk,
    c.c_first_shipto_date_sk,
    i.i_category,
    s.s_market_desc
),
agg2 AS (
  SELECT
    ba.sr_store_sk,
    ba.sr_customer_sk,
    ba.i_category,
    ba.s_market_desc,
    ba.c_first_shipto_date_sk,
    SUM(ba.total_return_inc_tax) AS store_category_return,
    AVG(ba.cnt_returns) AS avg_cnt_returns
  FROM base_agg ba
  WHERE ba.total_return_inc_tax > 50
  GROUP BY
    ba.sr_store_sk,
    ba.sr_customer_sk,
    ba.i_category,
    ba.s_market_desc,
    ba.c_first_shipto_date_sk
),
unioned AS (
  SELECT
    a.sr_store_sk,
    a.sr_customer_sk,
    a.i_category,
    a.s_market_desc,
    a.c_first_shipto_date_sk,
    a.store_category_return,
    a.avg_cnt_returns
  FROM agg2 a
  WHERE a.store_category_return > 1000
  UNION DISTINCT
  SELECT
    a.sr_store_sk,
    a.sr_customer_sk,
    a.i_category,
    a.s_market_desc,
    a.c_first_shipto_date_sk,
    a.store_category_return,
    a.avg_cnt_returns
  FROM agg2 a
  WHERE a.avg_cnt_returns < 5
)
SELECT
  u.sr_store_sk,
  u.sr_customer_sk,
  u.i_category,
  u.s_market_desc,
  u.c_first_shipto_date_sk,
  u.store_category_return,
  u.avg_cnt_returns,
  CASE
    WHEN u.store_category_return > 5000 THEN 'VERY HIGH'
    WHEN u.store_category_return > 2000 THEN 'HIGH'
    ELSE 'NORMAL'
  END AS return_volume_level,
  RANK() OVER (PARTITION BY u.i_category ORDER BY u.store_category_return DESC) AS category_rank
FROM unioned u
WHERE u.sr_customer_sk NOT IN (
    SELECT c.c_customer_sk
    FROM customer c
    WHERE c.c_preferred_cust_flag = 'Y'
)
ORDER BY u.i_category, category_rank
LIMIT 100
