WITH
  -- Orders that appear in both web_sales and catalog_returns
  intersect_orders AS (
    SELECT ws.ws_order_number
    FROM web_sales ws
    INTERSECT
    SELECT cr.cr_order_number
    FROM catalog_returns cr
  ),

  -- Base join of all 14 tables following the allowed join rules (left‑deep chain)
  base AS (
    SELECT
      sr.sr_store_sk,
      s.s_store_name,
      d.d_year,
      ca.ca_state,
      cd.cd_gender,
      hd.hd_income_band_sk,
      r.r_reason_desc,
      cr.cr_return_amount,
      cp.cp_department,
      sm.sm_type,
      ws.ws_order_number,
      ws.ws_ext_sales_price,
      wp.wp_type,
      we.web_name,
      sr.sr_return_amt
    FROM store_returns sr
    JOIN date_dim d
      ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN customer_demographics cd
      ON sr.sr_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd
      ON sr.sr_hdemo_sk = hd.hd_demo_sk
    JOIN customer_address ca
      ON sr.sr_addr_sk = ca.ca_address_sk
    JOIN store s
      ON sr.sr_store_sk = s.s_store_sk
    JOIN reason r
      ON sr.sr_reason_sk = r.r_reason_sk
    JOIN catalog_returns cr
      ON cr.cr_returned_date_sk = d.d_date_sk
     AND cr.cr_reason_sk = r.r_reason_sk
    JOIN catalog_page cp
      ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN ship_mode sm
      ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN web_sales ws
      ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN web_page wp
      ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN web_site we
      ON ws.ws_web_site_sk = we.web_site_sk
    WHERE d.d_year = 2001
      AND ca.ca_state = 'CA'
      AND r.r_reason_desc LIKE '%damaged%'
      AND sm.sm_type = 'AIR'
  )

SELECT
  agg.s_store_name,
  agg.d_year,
  SUM(agg.store_return_total) AS total_store_returns,
  AVG(agg.ws_ext_sales_price) AS avg_sales_price,
  COUNT(DISTINCT agg.ws_order_number) AS num_orders
FROM (
  SELECT
    b.s_store_name,
    b.d_year,
    lt.store_return_total,
    b.ws_ext_sales_price,
    b.ws_order_number,
    b.sr_store_sk
  FROM base b
  -- LATERAL join to compute total return amount for the current store
  CROSS JOIN LATERAL (
    SELECT SUM(sr2.sr_return_amt) AS store_return_total
    FROM store_returns sr2
    WHERE sr2.sr_store_sk = b.sr_store_sk
  ) lt
  WHERE b.ws_order_number IN (SELECT ws_order_number FROM intersect_orders)
    AND NOT EXISTS (
      SELECT 1
      FROM web_returns wr
      WHERE wr.wr_order_number = b.ws_order_number
    )
) agg
GROUP BY agg.s_store_name, agg.d_year
HAVING SUM(agg.store_return_total) > 1000
ORDER BY total_store_returns DESC
OFFSET 0 FETCH NEXT 100 ROWS ONLY
