WITH
  cr AS (
    SELECT *
    FROM catalog_returns
  ),
  cp AS (
    SELECT *
    FROM catalog_page
  ),
  dr_return AS (
    SELECT *
    FROM date_dim
  ),
  cr_time AS (
    SELECT *
    FROM time_dim
  ),
  cr_reason AS (
    SELECT *
    FROM reason
  ),
  cp_start_date AS (
    SELECT *
    FROM date_dim
  ),
  cp_end_date AS (
    SELECT *
    FROM date_dim
  ),
  wr AS (
    SELECT *
    FROM web_returns
  ),
  wr_time AS (
    SELECT *
    FROM time_dim
  ),
  wr_reason AS (
    SELECT *
    FROM reason
  )
SELECT
  cr_reason.r_reason_desc AS return_reason,
  cp.cp_department AS department,
  dr_return.d_year AS return_year,
  SUM(cr.cr_return_amount) AS total_catalog_return_amount,
  SUM(wr.wr_return_amt) AS total_web_return_amount,
  COUNT(DISTINCT cr.cr_order_number) AS catalog_return_orders,
  COUNT(DISTINCT wr.wr_order_number) AS web_return_orders
FROM cr
JOIN cp
  ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
JOIN dr_return
  ON cr.cr_returned_date_sk = dr_return.d_date_sk
JOIN cr_time
  ON cr.cr_returned_time_sk = cr_time.t_time_sk
JOIN cr_reason
  ON cr.cr_reason_sk = cr_reason.r_reason_sk
JOIN cp_start_date
  ON cp.cp_start_date_sk = cp_start_date.d_date_sk
JOIN cp_end_date
  ON cp.cp_end_date_sk = cp_end_date.d_date_sk
JOIN wr
  ON wr.wr_returned_date_sk = dr_return.d_date_sk
JOIN wr_time
  ON wr.wr_returned_time_sk = wr_time.t_time_sk
JOIN wr_reason
  ON wr.wr_reason_sk = wr_reason.r_reason_sk
GROUP BY
  cr_reason.r_reason_desc,
  cp.cp_department,
  dr_return.d_year
ORDER BY total_catalog_return_amount DESC
LIMIT 100
