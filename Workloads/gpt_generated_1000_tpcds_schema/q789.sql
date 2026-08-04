WITH
  -- aggregate store sales per customer
  cust_sales AS (
    SELECT
      c.c_customer_sk,
      c.c_customer_id,
      SUM(ss.ss_ext_sales_price) AS total_sales,
      SUM(ss.ss_net_profit)      AS total_profit
    FROM store_sales ss
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    WHERE ss.ss_ext_sales_price > 1000                     -- predicate 1
      AND ss.ss_ext_tax BETWEEN 5 AND 200                  -- predicate 2
    GROUP BY c.c_customer_sk, c.c_customer_id
  ),

  -- aggregate returns per customer (catalog + web) and bring ship mode info
  cust_returns AS (
    SELECT
      c.c_customer_sk,
      c.c_customer_id,
      SUM(cr.cr_return_amount)   AS catalog_ret_amount,
      SUM(cr.cr_net_loss)        AS catalog_net_loss,
      SUM(wr.wr_return_amt)     AS web_ret_amount,
      SUM(wr.wr_net_loss)        AS web_net_loss,
      MAX(sm.sm_type)            AS ship_type
    FROM customer c
    LEFT JOIN catalog_returns cr ON cr.cr_refunded_customer_sk = c.c_customer_sk
    LEFT JOIN ship_mode sm       ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    LEFT JOIN web_returns wr    ON wr.wr_refunded_customer_sk = c.c_customer_sk
    WHERE (cr.cr_return_amount > 50 OR cr.cr_return_amount IS NULL)   -- predicate 3
      AND (wr.wr_return_amt    > 30 OR wr.wr_return_amt IS NULL)      -- predicate 4
    GROUP BY c.c_customer_sk, c.c_customer_id
  ),

  -- keep every customer that appears in either sales or returns
  full_data AS (
    SELECT
      COALESCE(cs.c_customer_sk, cr.c_customer_sk) AS customer_sk,
      COALESCE(cs.c_customer_id, cr.c_customer_id) AS customer_id,
      cs.total_sales,
      cs.total_profit,
      cr.catalog_ret_amount,
      cr.catalog_net_loss,
      cr.web_ret_amount,
      cr.web_net_loss,
      cr.ship_type
    FROM cust_sales cs
    FULL OUTER JOIN cust_returns cr
      ON cs.c_customer_sk = cr.c_customer_sk
  ),

  -- LATERAL subquery that counts how many times a specific reason appears for the customer
  reason_counts AS (
    SELECT
      fd.customer_sk,
      fd.customer_id,
      fd.total_sales,
      fd.total_profit,
      fd.catalog_ret_amount,
      fd.web_ret_amount,
      fd.ship_type,
      rc.reason_cnt,
      CASE
        WHEN fd.total_sales IS NULL                     THEN 'No Sales'
        WHEN fd.total_sales > 10000                     THEN 'High Sales'
        ELSE 'Regular Sales'
      END AS sales_category
    FROM full_data fd
    LEFT JOIN LATERAL (
      SELECT COUNT(*) AS reason_cnt
      FROM catalog_returns cr
      JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
      WHERE cr.cr_refunded_customer_sk = fd.customer_sk
        AND r.r_reason_id = 'AAAAAAAADAAAAAAA'            -- predicate 5
    ) rc ON TRUE
  ),

  -- scalar subquery that provides the overall average net loss (catalog + web)
  overall_avg_loss AS (
    SELECT AVG(net_loss) AS avg_net_loss FROM (
      SELECT cr.cr_net_loss   AS net_loss FROM catalog_returns cr
      UNION ALL
      SELECT wr.wr_net_loss  AS net_loss FROM web_returns wr
    )
  ),

  -- final set with window functions, CASE logic and anti‑semi‑join
  final_set AS (
    SELECT
      rc.customer_id,
      rc.total_sales,
      rc.total_profit,
      rc.catalog_ret_amount,
      rc.web_ret_amount,
      (rc.catalog_ret_amount + rc.web_ret_amount) AS total_return_amount,
      rc.sales_category,
      rc.ship_type,
      rc.reason_cnt,
      oa.avg_net_loss,
      CASE
        WHEN (rc.catalog_ret_amount + rc.web_ret_amount) > 5000 THEN 'High Returns'
        ELSE 'Normal Returns'
      END AS return_flag,
      ROW_NUMBER() OVER (PARTITION BY rc.sales_category ORDER BY (rc.catalog_ret_amount + rc.web_ret_amount) DESC) AS rn_category,
      RANK()       OVER (ORDER BY (rc.catalog_ret_amount + rc.web_ret_amount) DESC)          AS sales_return_rank
    FROM reason_counts rc
    CROSS JOIN overall_avg_loss oa
    WHERE rc.customer_id NOT IN (
            SELECT c.c_customer_id
            FROM customer c
            WHERE c.c_birth_day = 8          -- anti‑semi‑join condition
          )
      AND rc.total_sales > 0
      AND (rc.catalog_ret_amount IS NOT NULL OR rc.web_ret_amount IS NOT NULL)
  )

SELECT
  customer_id,
  total_sales,
  total_profit,
  total_return_amount,
  sales_category,
  ship_type,
  return_flag,
  sales_return_rank
FROM final_set
WHERE sales_return_rank <= 50

UNION DISTINCT

SELECT
  customer_id,
  total_sales,
  total_profit,
  total_return_amount,
  sales_category,
  ship_type,
  return_flag,
  sales_return_rank
FROM final_set
WHERE sales_category = 'High Sales'

ORDER BY sales_return_rank
LIMIT 100
