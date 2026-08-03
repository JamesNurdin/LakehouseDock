WITH
  store_data AS (
    SELECT
      c.c_customer_sk,
      c.c_customer_id,
      c.c_birth_year,
      s.s_state AS store_state,
      ss.ss_net_paid,
      ss.ss_net_profit,
      hd.hd_income_band_sk,
      ib.ib_lower_bound,
      ib.ib_upper_bound
    FROM store_sales ss
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE c.c_birth_year BETWEEN 1960 AND 1970
      AND s.s_state = 'CA'
  ),
  web_return_data AS (
    SELECT
      ws.ws_order_number,
      ws.ws_net_paid_inc_ship_tax,
      ws.ws_ship_mode_sk,
      ws.ws_warehouse_sk,
      ws.ws_bill_customer_sk,
      wp.wp_type,
      we.web_state,
      wp.wp_link_count,
      wp.wp_max_ad_count,
      sm.sm_type AS ship_type,
      w.w_warehouse_name
    FROM web_sales ws
    LEFT JOIN web_returns wr ON wr.wr_order_number = ws.ws_order_number
    JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN web_site we ON ws.ws_web_site_sk = we.web_site_sk
    WHERE we.web_state = 'CA'
      AND wp.wp_link_count > 10
      AND wp.wp_max_ad_count = 1
  ),
  catalog_data AS (
    SELECT
      cr.cr_refunded_customer_sk,
      cr.cr_return_amount,
      cr.cr_return_quantity,
      cp.cp_department,
      sm.sm_type AS ship_type,
      w.w_warehouse_name,
      r.r_reason_desc
    FROM catalog_returns cr
    JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    WHERE cp.cp_department = 'Electronics'
      AND cr.cr_return_quantity > 1
      AND sm.sm_carrier = 'UPS'
  )
SELECT DISTINCT
  COALESCE(sd.c_customer_id, CAST(wrd.ws_order_number AS VARCHAR)) AS entity_id,
  sd.c_birth_year,
  sd.store_state,
  wrd.ws_net_paid_inc_ship_tax,
  rd.r_reason_desc,
  rd.cp_department,
  rd.ship_type,
  rd.w_warehouse_name,
  (COALESCE(sd.ss_net_paid, 0) + COALESCE(wrd.ws_net_paid_inc_ship_tax, 0) + COALESCE(rd.cr_return_amount, 0)) AS total_amount,
  ROW_NUMBER() OVER (
    PARTITION BY COALESCE(sd.c_customer_sk, wrd.ws_bill_customer_sk)
    ORDER BY COALESCE(sd.ss_net_paid, 0) DESC
  ) AS rn_customer,
  RANK() OVER (
    ORDER BY (COALESCE(sd.ss_net_paid, 0) + COALESCE(wrd.ws_net_paid_inc_ship_tax, 0) + COALESCE(rd.cr_return_amount, 0)) DESC
  ) AS total_rank
FROM store_data sd
FULL OUTER JOIN web_return_data wrd
  ON sd.c_customer_sk = wrd.ws_bill_customer_sk
LEFT JOIN catalog_data rd
  ON rd.cr_refunded_customer_sk = sd.c_customer_sk
WHERE (sd.c_birth_year IS NOT NULL OR wrd.ws_net_paid_inc_ship_tax > 500)
  AND (rd.cp_department IS NOT NULL OR rd.r_reason_desc LIKE '%price%')
ORDER BY total_amount DESC
LIMIT 100
