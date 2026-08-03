WITH
  returns_excluding AS (
    SELECT sr.sr_store_sk
    FROM store_returns sr
    EXCEPT
    SELECT s2.s_store_sk
    FROM store s2
    WHERE s2.s_state = 'CA'
  ),
  base AS (
    SELECT
      cs.cs_sold_date_sk,
      cs.cs_sold_time_sk,
      cs.cs_item_sk,
      cs.cs_ext_sales_price,
      cs.cs_net_profit,
      cs.cs_bill_hdemo_sk,
      cs.cs_bill_addr_sk,
      cs.cs_ship_hdemo_sk,
      cs.cs_ship_addr_sk,
      cs.cs_call_center_sk,
      cs.cs_catalog_page_sk,
      cs.cs_ship_mode_sk,
      cs.cs_warehouse_sk,
      sr.sr_store_sk,
      sr.sr_return_quantity,
      r.r_reason_desc,
      s.s_store_name,
      cc.cc_name,
      cp.cp_type,
      sm.sm_type,
      w.w_warehouse_name,
      wp.wp_web_page_sk,
      inv.inv_quantity_on_hand,
      CASE WHEN r.r_reason_desc = 'Damaged' THEN 1 ELSE 0 END AS damaged_flag,
      wr.wr_net_loss
    FROM catalog_sales cs
    LEFT JOIN time_dim td ON cs.cs_sold_time_sk = td.t_time_sk
    LEFT JOIN household_demographics hd_bill ON cs.cs_bill_hdemo_sk = hd_bill.hd_demo_sk
    LEFT JOIN income_band ib ON hd_bill.hd_income_band_sk = ib.ib_income_band_sk
    LEFT JOIN customer_address ca_bill ON cs.cs_bill_addr_sk = ca_bill.ca_address_sk
    LEFT JOIN household_demographics hd_ship ON cs.cs_ship_hdemo_sk = hd_ship.hd_demo_sk
    LEFT JOIN customer_address ca_ship ON cs.cs_ship_addr_sk = ca_ship.ca_address_sk
    LEFT JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    LEFT JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    LEFT JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    LEFT JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    LEFT JOIN inventory inv ON inv.inv_warehouse_sk = w.w_warehouse_sk
    LEFT JOIN store_returns sr ON sr.sr_return_time_sk = td.t_time_sk
    RIGHT OUTER JOIN store s ON sr.sr_store_sk = s.s_store_sk
    LEFT JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    LEFT JOIN web_sales ws ON ws.ws_warehouse_sk = w.w_warehouse_sk
                               AND ws.ws_sold_time_sk = td.t_time_sk
    LEFT JOIN web_returns wr ON wr.wr_order_number = ws.ws_order_number
    LEFT JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
  )
SELECT
  s_store_name,
  cc_name,
  cp_type,
  sm_type,
  w_warehouse_name,
  CASE
    WHEN SUM(cs_net_profit) > 0 THEN 'Profitable'
    ELSE 'Loss'
  END AS profit_flag,
  COUNT(DISTINCT cs_item_sk) AS distinct_items_sold,
  SUM(cs_ext_sales_price) AS total_sales,
  SUM(COALESCE(wr_net_loss, 0)) AS total_web_returns_loss,
  SUM(damaged_flag) AS damaged_return_count
FROM base
WHERE EXISTS (
  SELECT 1
  FROM returns_excluding re
  WHERE re.sr_store_sk = base.sr_store_sk
)
GROUP BY
  s_store_name,
  cc_name,
  cp_type,
  sm_type,
  w_warehouse_name
ORDER BY total_sales DESC
LIMIT 100
