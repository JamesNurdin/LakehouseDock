WITH
  catalog_ret_customers AS (
    SELECT DISTINCT
      cr.cr_returning_customer_sk AS customer_sk,
      cr.cr_return_amount,
      cr.cr_net_loss,
      cr.cr_returned_date_sk
    FROM catalog_returns cr
    JOIN catalog_page cp
      ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN customer c
      ON cr.cr_returning_customer_sk = c.c_customer_sk
    WHERE regexp_like(cp.cp_description, '^.*Return.*$')
      AND c.c_first_name LIKE 'A%'
  ),
  web_ret_customers AS (
    SELECT DISTINCT
      wr.wr_returning_customer_sk AS customer_sk,
      wr.wr_return_amt,
      wr.wr_net_loss,
      wr.wr_returned_date_sk
    FROM web_returns wr
    JOIN customer c
      ON wr.wr_returning_customer_sk = c.c_customer_sk
    WHERE regexp_like(CAST(wr.wr_return_amt AS VARCHAR), '^[0-9]+\\.?[0-9]*$')
      AND c.c_last_name LIKE '%son'
  ),
  intersect_customers AS (
    SELECT customer_sk FROM catalog_ret_customers
    INTERSECT
    SELECT customer_sk FROM web_ret_customers
  ),
  except_customers AS (
    SELECT customer_sk FROM catalog_ret_customers
    EXCEPT
    SELECT customer_sk FROM web_ret_customers
  ),
  catalog_return_agg AS (
    SELECT
      cr_returning_customer_sk AS customer_sk,
      SUM(cr_return_amount) AS total_return_amount,
      AVG(cr_return_amount) AS avg_return_amount
    FROM catalog_returns
    GROUP BY cr_returning_customer_sk
  ),
  customer_spent AS (
    SELECT
      ss.ss_customer_sk AS customer_sk,
      SUM(ss.ss_net_paid) AS total_spent
    FROM store_sales ss
    GROUP BY ss.ss_customer_sk
  ),
  customer_rank AS (
    SELECT
      customer_sk,
      total_spent,
      ROW_NUMBER() OVER (ORDER BY total_spent DESC) AS spend_rank
    FROM customer_spent
  )
SELECT DISTINCT
  ic.customer_sk,
  CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
  cra.total_return_amount,
  cra.avg_return_amount,
  CASE WHEN cra.avg_return_amount > 50 THEN 'High' ELSE 'Low' END AS return_level,
  crk.total_spent,
  crk.spend_rank,
  sm.sm_ship_mode_id
FROM intersect_customers ic
JOIN customer c
  ON ic.customer_sk = c.c_customer_sk
LEFT JOIN catalog_return_agg cra
  ON ic.customer_sk = cra.customer_sk
LEFT JOIN customer_rank crk
  ON ic.customer_sk = crk.customer_sk
LEFT JOIN (
  SELECT DISTINCT
    cr.cr_returning_customer_sk AS customer_sk,
    sm.sm_ship_mode_id
  FROM catalog_returns cr
  JOIN ship_mode sm
    ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
  WHERE sm.sm_contract LIKE 'Y%'
) sm
  ON ic.customer_sk = sm.customer_sk
WHERE POSITION('a' IN LOWER(CONCAT(c.c_first_name, c.c_last_name))) > 0
ORDER BY cra.total_return_amount DESC NULLS LAST
LIMIT 100
