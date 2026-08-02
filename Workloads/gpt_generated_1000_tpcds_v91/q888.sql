/*
Goal: Analyze total return amounts and quantities by catalog page type and return year, using deep joins across all five TPC‑DS tables with multiple aliases, an outer join on addresses, an INTERSECT of order numbers, ROLLUP subtotals and a ranking window function.
*/
WITH
  base AS (
    SELECT
      cr.cr_returned_date_sk,
      cr.cr_returned_time_sk,
      cr.cr_order_number,
      cr.cr_return_amount,
      cr.cr_return_quantity,
      cp.cp_type,
      cp.cp_catalog_page_number,
      ret_date.d_year               AS return_year,
      ret_time.t_hour               AS return_hour,
      refunded_addr.ca_state        AS refunded_state,
      returning_addr.ca_state       AS returning_state,
      page_start_date.d_month_seq   AS start_month_seq,
      page_end_date.d_month_seq     AS end_month_seq,
      cp2.cp_type                   AS cp_type_dup,
      refunded_addr2.ca_country     AS refunded_country_dup
    FROM catalog_returns cr
    JOIN date_dim ret_date
      ON cr.cr_returned_date_sk = ret_date.d_date_sk
    JOIN time_dim ret_time
      ON cr.cr_returned_time_sk = ret_time.t_time_sk
    LEFT JOIN customer_address refunded_addr
      ON cr.cr_refunded_addr_sk = refunded_addr.ca_address_sk
    LEFT JOIN customer_address returning_addr
      ON cr.cr_returning_addr_sk = returning_addr.ca_address_sk
    JOIN catalog_page cp
      ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN date_dim page_start_date
      ON cp.cp_start_date_sk = page_start_date.d_date_sk
    JOIN date_dim page_end_date
      ON cp.cp_end_date_sk = page_end_date.d_date_sk
    JOIN catalog_page cp2
      ON cr.cr_catalog_page_sk = cp2.cp_catalog_page_sk
    JOIN customer_address refunded_addr2
      ON cr.cr_refunded_addr_sk = refunded_addr2.ca_address_sk
  ),
  intersect_orders AS (
    SELECT cr.cr_order_number
    FROM catalog_returns cr
    JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    WHERE cp.cp_type = 'monthly'
    INTERSECT
    SELECT cr.cr_order_number
    FROM catalog_returns cr
    JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    WHERE cp.cp_type = 'quarterly'
  ),
  agg AS (
    SELECT
      base.cp_type,
      base.return_year,
      COUNT(DISTINCT base.cr_order_number) AS num_orders,
      SUM(base.cr_return_amount)          AS total_return_amount,
      SUM(base.cr_return_quantity)        AS total_quantity
    FROM base
    JOIN intersect_orders io
      ON base.cr_order_number = io.cr_order_number
    GROUP BY ROLLUP (base.cp_type, base.return_year)
  )
SELECT
  cp_type,
  return_year,
  num_orders,
  total_return_amount,
  total_quantity,
  RANK() OVER (PARTITION BY return_year ORDER BY total_return_amount DESC) AS amount_rank
FROM agg
ORDER BY return_year DESC, cp_type
LIMIT 100
