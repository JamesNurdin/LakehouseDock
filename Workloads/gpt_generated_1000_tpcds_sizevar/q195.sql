WITH
  sales_agg AS (
    SELECT
      ss.ss_customer_sk,
      SUM(ss.ss_net_paid)               AS total_paid,
      COUNT(*)                           AS txn_cnt
    FROM tpcds.store_sales ss
    WHERE ss.ss_ext_wholesale_cost > 500
      AND ss.ss_net_paid > 1000
    GROUP BY ss.ss_customer_sk
  ),
  returns_filtered AS (
    SELECT DISTINCT
      sr.sr_customer_sk
    FROM tpcds.store_returns sr
    JOIN tpcds.reason r
      ON sr.sr_reason_sk = r.r_reason_sk
    WHERE sr.sr_return_amt > 200
      AND r.r_reason_desc LIKE '%size%'
  ),
  intersect_customers AS (
    SELECT ss_customer_sk FROM sales_agg
    INTERSECT
    SELECT sr_customer_sk FROM returns_filtered
  ),
  top_sales AS (
    SELECT
      ss.ss_customer_sk,
      ss.ss_item_sk,
      ss.ss_net_paid,
      ROW_NUMBER() OVER (PARTITION BY ss.ss_customer_sk ORDER BY ss.ss_net_paid DESC) AS rn
    FROM tpcds.store_sales ss
    WHERE ss.ss_customer_sk IN (SELECT ss_customer_sk FROM intersect_customers)
  )
SELECT
  c.c_customer_id,
  c.c_first_name,
  c.c_last_name,
  cd.cd_gender,
  hd.hd_buy_potential,
  i.i_product_name,
  sa.total_paid,
  RANK() OVER (ORDER BY sa.total_paid DESC) AS revenue_rank
FROM intersect_customers ic
JOIN tpcds.store_sales ss
  ON ic.ss_customer_sk = ss.ss_customer_sk
JOIN sales_agg sa
  ON ss.ss_customer_sk = sa.ss_customer_sk
JOIN top_sales ts
  ON ss.ss_customer_sk = ts.ss_customer_sk
  AND ts.rn = 1
JOIN tpcds.customer c
  ON ss.ss_customer_sk = c.c_customer_sk
JOIN tpcds.customer_demographics cd
  ON c.c_current_cdemo_sk = cd.cd_demo_sk
JOIN tpcds.household_demographics hd
  ON c.c_current_hdemo_sk = hd.hd_demo_sk
JOIN tpcds.item i
  ON ts.ss_item_sk = i.i_item_sk
WHERE c.c_birth_year BETWEEN 1950 AND 1970
  AND c.c_preferred_cust_flag = 'Y'
  AND i.i_current_price > 20
ORDER BY revenue_rank
LIMIT 100
