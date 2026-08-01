WITH
  returns_lateral AS (
    SELECT
      d.d_year,
      d.d_month_seq,
      CASE WHEN cr.cr_return_amount > 0 THEN 'Positive' ELSE 'Non-Positive' END AS return_type,
      cr.cr_return_amount,
      cr.cr_return_quantity,
      cr.cr_returning_customer_sk,
      wp_l.wp_cnt
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    CROSS JOIN LATERAL (
      SELECT COUNT(*) AS wp_cnt
      FROM web_page wp
      WHERE wp.wp_customer_sk = cr.cr_returning_customer_sk
        AND wp.wp_access_date_sk = cr.cr_returned_date_sk
    ) wp_l
  ),
  returns_customers AS (
    SELECT DISTINCT cr.cr_returning_customer_sk AS cust_sk
    FROM catalog_returns cr
  ),
  webpage_customers AS (
    SELECT DISTINCT wp.wp_customer_sk AS cust_sk
    FROM web_page wp
  ),
  customers_no_web AS (
    SELECT cust_sk
    FROM returns_customers
    EXCEPT
    SELECT cust_sk
    FROM webpage_customers
  ),
  agg_returns AS (
    SELECT d.d_year, d.d_month_seq,
           SUM(cr.cr_return_amount)   AS sum_return_amount,
           SUM(cr.cr_return_quantity) AS sum_return_quantity
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    GROUP BY d.d_year, d.d_month_seq
  ),
  agg_web AS (
    SELECT d.d_year, d.d_month_seq,
           COUNT(wp.wp_web_page_sk) AS wp_page_cnt
    FROM web_page wp
    JOIN date_dim d ON wp.wp_access_date_sk = d.d_date_sk
    GROUP BY d.d_year, d.d_month_seq
  ),
  full_joined AS (
    SELECT
      COALESCE(r.d_year, w.d_year)         AS year,
      COALESCE(r.d_month_seq, w.d_month_seq) AS month,
      r.sum_return_amount,
      r.sum_return_quantity,
      w.wp_page_cnt
    FROM agg_returns r
    FULL OUTER JOIN agg_web w
      ON r.d_year = w.d_year AND r.d_month_seq = w.d_month_seq
  ),
  unioned AS (
    SELECT
      rl.d_year  AS year,
      rl.d_month_seq AS month,
      rl.return_type,
      rl.cr_return_amount AS amount,
      rl.cr_return_quantity AS qty,
      rl.wp_cnt
    FROM returns_lateral rl
    WHERE rl.cr_returning_customer_sk IN (SELECT cust_sk FROM customers_no_web)
    UNION
    SELECT
      f.year,
      f.month,
      'Aggregated' AS return_type,
      f.sum_return_amount AS amount,
      f.sum_return_quantity AS qty,
      f.wp_page_cnt AS wp_cnt
    FROM full_joined f
  )
SELECT
  year,
  month,
  return_type,
  SUM(amount) AS total_amount,
  SUM(qty)    AS total_quantity,
  SUM(wp_cnt) AS total_wp_cnt
FROM unioned
GROUP BY ROLLUP (year, month, return_type)
ORDER BY year NULLS LAST, month NULLS LAST, return_type
OFFSET 0 FETCH NEXT 100 ROWS ONLY
