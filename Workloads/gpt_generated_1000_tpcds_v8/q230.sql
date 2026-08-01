WITH
  sales AS (
    SELECT
      cs.cs_order_number,
      cs.cs_sales_price,
      cs.cs_ext_tax,
      cs.cs_coupon_amt,
      d.d_year,
      cp.cp_type,
      cp.cp_description,
      sm.sm_type,
      sm.sm_carrier,
      cs.cs_catalog_page_sk,
      cs.cs_ship_mode_sk
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE d.d_year = 2001
      AND regexp_like(cp.cp_description, '.*[Rr]egion.*')
      AND cp.cp_type LIKE 'C%'
  ),
  returns AS (
    SELECT cr.cr_order_number
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
      AND cr.cr_return_amount > 0
  ),
  non_returned_orders AS (
    SELECT s.cs_order_number
    FROM sales s
    EXCEPT
    SELECT r.cr_order_number
    FROM returns r
  ),
  sales_nr AS (
    SELECT
      s.cs_order_number,
      s.cs_sales_price,
      s.cs_ext_tax,
      s.cs_coupon_amt,
      s.d_year,
      s.cp_type,
      s.sm_type,
      s.sm_carrier
    FROM sales s
    JOIN non_returned_orders nro ON s.cs_order_number = nro.cs_order_number
  )
SELECT
  snr.cp_type,
  snr.sm_type,
  COUNT(*)                                   AS order_cnt,
  SUM(snr.cs_sales_price)                    AS total_sales,
  AVG(snr.cs_sales_price)                    AS avg_sales,
  ROW_NUMBER() OVER (PARTITION BY snr.cp_type ORDER BY SUM(snr.cs_sales_price) DESC) AS rn,
  lt.combined_type,
  lt.carrier_prefix
FROM sales_nr snr
JOIN LATERAL (
  SELECT
    concat(snr.cp_type, '-', snr.sm_type) AS combined_type,
    substr(snr.sm_carrier, 1, 3)           AS carrier_prefix
) lt ON true
GROUP BY
  snr.cp_type,
  snr.sm_type,
  lt.combined_type,
  lt.carrier_prefix
HAVING COUNT(*) > 5
ORDER BY total_sales DESC
LIMIT 100
