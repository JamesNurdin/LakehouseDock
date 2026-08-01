/*
Goal: Produce a deep‑analysis of item performance by combining store sales, web sales, returns, and various dimension tables. The query joins all 16 selected TPC‑DS tables, uses CTEs, scalar and set sub‑queries, DISTINCT, an EXISTS semi‑join, INTERSECT/EXCEPT, and pages the ordered result.
*/
WITH
  base_sales AS (
    SELECT
      ss.ss_item_sk,
      SUM(ss.ss_net_profit) AS store_profit,
      COUNT(DISTINCT ss.ss_ticket_number) AS store_txns
    FROM store_sales ss
    JOIN time_dim td ON ss.ss_sold_time_sk = td.t_time_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    GROUP BY ss.ss_item_sk
  ),
  item_web AS (
    SELECT
      ws.ws_item_sk,
      SUM(ws.ws_net_profit) AS web_profit,
      SUM(ws.ws_quantity) AS web_qty,
      MAX(ws_site.web_name) AS web_site_name
    FROM web_sales ws
    JOIN time_dim td ON ws.ws_sold_time_sk = td.t_time_sk
    JOIN web_site ws_site ON ws.ws_web_site_sk = ws_site.web_site_sk
    GROUP BY ws.ws_item_sk
  ),
  returns_inter AS (
    SELECT cr.cr_item_sk
    FROM catalog_returns cr
    INTERSECT
    SELECT wr.wr_item_sk
    FROM web_returns wr
  ),
  returns_excl AS (
    SELECT cr.cr_item_sk
    FROM catalog_returns cr
    EXCEPT
    SELECT wr.wr_item_sk
    FROM web_returns wr
  )
SELECT DISTINCT
  i.i_item_id,
  i.i_product_name,
  i.i_category,
  i.i_brand,
  bs.store_profit,
  iw.web_profit,
  iw.web_site_name,
  cc.cc_name,
  cp.cp_description,
  sm.sm_carrier,
  w.w_warehouse_name,
  ib.ib_lower_bound,
  ib.ib_upper_bound,
  ca.ca_city,
  cd.cd_gender,
  (
    SELECT AVG(ws2.ws_net_paid)
    FROM web_sales ws2
    WHERE ws2.ws_item_sk = i.i_item_sk
  ) AS avg_ws_net_paid
FROM base_sales bs
JOIN item i ON bs.ss_item_sk = i.i_item_sk
LEFT JOIN item_web iw ON i.i_item_sk = iw.ws_item_sk
LEFT JOIN catalog_returns cr ON i.i_item_sk = cr.cr_item_sk
LEFT JOIN web_returns wr ON i.i_item_sk = wr.wr_item_sk
LEFT JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
LEFT JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
LEFT JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
LEFT JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
LEFT JOIN household_demographics hd ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
LEFT JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
LEFT JOIN customer_address ca ON cr.cr_refunded_addr_sk = ca.ca_address_sk
LEFT JOIN customer_demographics cd ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
LEFT JOIN promotion promo ON promo.p_item_sk = i.i_item_sk
WHERE EXISTS (
  SELECT 1
  FROM catalog_returns cr2
  WHERE cr2.cr_item_sk = i.i_item_sk
    AND cr2.cr_return_quantity > 5
)
AND i.i_item_sk IN (SELECT cr_item_sk FROM returns_inter)
AND i.i_item_sk NOT IN (SELECT cr_item_sk FROM returns_excl)
ORDER BY bs.store_profit DESC, i.i_item_id
OFFSET 0
LIMIT 100
