WITH base_sales AS (
  SELECT
    s.s_store_id,
    i.i_item_id,
    i.i_category,
    SUM(ss.ss_ext_sales_price) AS store_sales_amount,
    SUM(cs.cs_ext_sales_price) AS catalog_sales_amount,
    SUM(ws.ws_ext_sales_price) AS web_sales_amount,
    COUNT(DISTINCT ss.ss_ticket_number) AS store_txn_cnt,
    COUNT(DISTINCT cs.cs_order_number) AS catalog_txn_cnt,
    COUNT(DISTINCT ws.ws_order_number) AS web_txn_cnt,
    ib.ib_income_band_sk
  FROM store_sales ss
  JOIN store s ON ss.ss_store_sk = s.s_store_sk
  JOIN item i ON ss.ss_item_sk = i.i_item_sk
  JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
  JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
  JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
  JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
  JOIN catalog_sales cs ON cs.cs_item_sk = i.i_item_sk
      AND cs.cs_bill_customer_sk = c.c_customer_sk
      AND cs.cs_bill_hdemo_sk = hd.hd_demo_sk
      AND cs.cs_promo_sk = p.p_promo_sk
  JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
  JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
  JOIN ship_mode sm_cs ON cs.cs_ship_mode_sk = sm_cs.sm_ship_mode_sk
  JOIN web_sales ws ON ws.ws_item_sk = i.i_item_sk
      AND ws.ws_bill_customer_sk = c.c_customer_sk
      AND ws.ws_bill_hdemo_sk = hd.hd_demo_sk
      AND ws.ws_promo_sk = p.p_promo_sk
  JOIN ship_mode sm_ws ON ws.ws_ship_mode_sk = sm_ws.sm_ship_mode_sk
  JOIN web_returns wr ON wr.wr_order_number = ws.ws_order_number
      AND wr.wr_item_sk = i.i_item_sk
  JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
  JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk
  WHERE i.i_manufact_id IN (167, 212)
    AND s.s_state = 'CA'
    AND ib.ib_upper_bound > 50000
  GROUP BY s.s_store_id, i.i_item_id, i.i_category, ib.ib_income_band_sk
)
SELECT
  s_store_id,
  i_item_id,
  i_category,
  store_sales_amount,
  catalog_sales_amount,
  web_sales_amount,
  CASE
    WHEN store_sales_amount > 100000 THEN 'HIGH'
    WHEN store_sales_amount BETWEEN 50000 AND 100000 THEN 'MEDIUM'
    ELSE 'LOW'
  END AS store_sales_level,
  RANK() OVER (ORDER BY store_sales_amount DESC) AS sales_rank,
  SUM(store_sales_amount) OVER (PARTITION BY i_category) AS cat_total_sales
FROM base_sales
ORDER BY sales_rank
LIMIT 100
