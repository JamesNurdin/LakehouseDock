WITH
  cs_agg AS (
    SELECT
      cs.cs_item_sk,
      cs.cs_bill_customer_sk,
      cs.cs_promo_sk,
      cs.cs_call_center_sk,
      cs.cs_catalog_page_sk,
      cs.cs_warehouse_sk,
      cs.cs_bill_hdemo_sk,
      SUM(cs.cs_ext_sales_price) AS catalog_sales_price,
      SUM(cs.cs_net_profit) AS catalog_profit
    FROM catalog_sales cs
    GROUP BY
      cs.cs_item_sk,
      cs.cs_bill_customer_sk,
      cs.cs_promo_sk,
      cs.cs_call_center_sk,
      cs.cs_catalog_page_sk,
      cs.cs_warehouse_sk,
      cs.cs_bill_hdemo_sk
  ),
  ss_agg AS (
    SELECT
      ss.ss_item_sk,
      SUM(ss.ss_ext_sales_price) AS store_sales_price,
      SUM(ss.ss_net_profit) AS store_profit
    FROM store_sales ss
    GROUP BY ss.ss_item_sk
  ),
  ws_agg AS (
    SELECT
      ws.ws_item_sk,
      SUM(ws.ws_ext_sales_price) AS web_sales_price,
      SUM(ws.ws_net_profit) AS web_profit
    FROM web_sales ws
    GROUP BY ws.ws_item_sk
  ),
  wr_agg AS (
    SELECT
      wr.wr_item_sk,
      SUM(wr.wr_return_amt) AS total_return_amount,
      SUM(wr.wr_net_loss) AS total_return_loss
    FROM web_returns wr
    GROUP BY wr.wr_item_sk
  ),
  inv_agg AS (
    SELECT
      inv.inv_item_sk,
      SUM(inv.inv_quantity_on_hand) AS total_on_hand
    FROM inventory inv
    GROUP BY inv.inv_item_sk
  ),
  joined AS (
    SELECT
      i.i_item_id,
      i.i_brand,
      i.i_category,
      i.i_manufact_id,
      c.c_first_name,
      c.c_last_name,
      hd.hd_income_band_sk,
      p.p_promo_name,
      cc.cc_name,
      cp.cp_department,
      w.w_warehouse_name,
      cs_agg.catalog_sales_price,
      cs_agg.catalog_profit,
      ss_agg.store_sales_price,
      ss_agg.store_profit,
      ws_agg.web_sales_price,
      ws_agg.web_profit,
      wr_agg.total_return_amount,
      wr_agg.total_return_loss,
      inv_agg.total_on_hand
    FROM cs_agg
    JOIN item i ON cs_agg.cs_item_sk = i.i_item_sk
    JOIN promotion p ON cs_agg.cs_promo_sk = p.p_promo_sk
    JOIN call_center cc ON cs_agg.cs_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp ON cs_agg.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN warehouse w ON cs_agg.cs_warehouse_sk = w.w_warehouse_sk
    JOIN customer c ON cs_agg.cs_bill_customer_sk = c.c_customer_sk
    JOIN household_demographics hd ON cs_agg.cs_bill_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN ss_agg ON ss_agg.ss_item_sk = cs_agg.cs_item_sk
    LEFT JOIN ws_agg ON ws_agg.ws_item_sk = cs_agg.cs_item_sk
    LEFT JOIN wr_agg ON wr_agg.wr_item_sk = cs_agg.cs_item_sk
    LEFT JOIN inv_agg ON inv_agg.inv_item_sk = cs_agg.cs_item_sk
    WHERE
      i.i_manufact_id IN (460, 260, 630)
      AND p.p_response_target = 1
      AND cc.cc_state = 'CA'
      AND cp.cp_department = 'Electronics'
      AND w.w_state = 'CA'
  )
SELECT
  i_item_id,
  i_brand,
  i_category,
  i_manufact_id,
  c_first_name,
  c_last_name,
  hd_income_band_sk,
  p_promo_name,
  cc_name,
  cp_department,
  w_warehouse_name,
  catalog_sales_price,
  catalog_profit,
  store_sales_price,
  store_profit,
  web_sales_price,
  web_profit,
  total_return_amount,
  total_return_loss,
  total_on_hand,
  (catalog_sales_price + COALESCE(store_sales_price, 0) + COALESCE(web_sales_price, 0) - COALESCE(total_return_amount, 0)) AS net_revenue
FROM joined
WHERE
  (catalog_sales_price + COALESCE(store_sales_price, 0) + COALESCE(web_sales_price, 0) - COALESCE(total_return_amount, 0)) > 10000
ORDER BY net_revenue DESC
LIMIT 100
