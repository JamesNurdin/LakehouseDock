WITH
  -- Sample a fraction of catalog_returns and apply several filters
  returns_sample AS (
    SELECT
      cr_returned_date_sk,
      cr_return_amt_inc_tax,
      cr_ship_mode_sk,
      cr_order_number,
      cr_return_quantity,
      cr_net_loss
    FROM catalog_returns
    TABLESAMPLE BERNOULLI (10)
    WHERE cr_ship_mode_sk IN (4, 5, 10, 12)
      AND cr_return_amt_inc_tax > 1000
      AND cr_return_quantity >= 1
      AND cr_net_loss IS NOT NULL
  ),
  -- Filter the date dimension on fiscal year, month sequence and a concrete date
  date_filtered AS (
    SELECT *
    FROM date_dim
    WHERE d_fy_year BETWEEN 1910 AND 1920
      AND d_month_seq >= 100
      AND d_date >= DATE '2000-01-01'
  ),
  -- Filter web pages on type, URL pattern and ensure an access date key exists
  web_filtered AS (
    SELECT *
    FROM web_page
    WHERE wp_type = 'content'
      AND wp_url LIKE '%.com%'
      AND wp_access_date_sk IS NOT NULL
  ),
  -- Join the three tables in a left‑deep chain
  joined AS (
    SELECT
      r.cr_order_number,
      r.cr_return_amt_inc_tax,
      r.cr_ship_mode_sk,
      d.d_year,
      d.d_fy_year,
      w.wp_web_page_id,
      w.wp_url,
      ROW_NUMBER() OVER (PARTITION BY d.d_fy_year ORDER BY r.cr_return_amt_inc_tax DESC) AS rn
    FROM returns_sample r
    JOIN date_filtered d ON r.cr_returned_date_sk = d.d_date_sk
    JOIN web_filtered w ON w.wp_access_date_sk = d.d_date_sk
  ),
  -- Sets of order numbers for set operations
  high_loss AS (
    SELECT cr_order_number FROM returns_sample WHERE cr_net_loss > 500
  ),
  low_loss AS (
    SELECT cr_order_number FROM returns_sample WHERE cr_net_loss < 100
  ),
  ship_mode_filter AS (
    SELECT cr_order_number FROM returns_sample WHERE cr_ship_mode_sk = 10 AND cr_return_amt_inc_tax > 2000
  ),
  -- Combine EXCEPT and INTERSECT to produce the final key set
  order_set AS (
    SELECT cr_order_number FROM high_loss
    EXCEPT
    SELECT cr_order_number FROM low_loss
    INTERSECT
    SELECT cr_order_number FROM ship_mode_filter
  )
SELECT
  j.cr_order_number,
  j.cr_return_amt_inc_tax,
  j.cr_ship_mode_sk,
  j.d_fy_year,
  j.wp_web_page_id,
  j.wp_url,
  j.rn
FROM joined j
WHERE j.cr_order_number IN (SELECT cr_order_number FROM order_set)
ORDER BY j.rn
LIMIT 100
