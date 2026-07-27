WITH
  sales_agg AS (
    SELECT
      i.i_item_sk,
      i.i_item_id,
      w.w_warehouse_sk,
      w.w_warehouse_name,
      cc.cc_call_center_sk,
      cc.cc_name AS call_center_name,
      SUM(cs.cs_ext_sales_price) AS total_sales,
      SUM(cs.cs_net_profit) AS total_profit,
      COUNT(DISTINCT cs.cs_order_number) AS orders_cnt
    FROM catalog_sales cs
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    WHERE p.p_discount_active = 'Y'
      AND i.i_brand_id IN (3003001, 10005006)
      AND i.i_size = 'large'
      AND w.w_state = 'CA'
      AND cc.cc_country = 'United States'
      AND cs.cs_sold_date_sk BETWEEN 2451545 AND 2451910
    GROUP BY i.i_item_sk, i.i_item_id, w.w_warehouse_sk, w.w_warehouse_name, cc.cc_call_center_sk, cc.cc_name
  ),
  returns_agg AS (
    SELECT
      i.i_item_sk,
      w.w_warehouse_sk,
      SUM(cr.cr_return_amount) AS total_returns,
      SUM(cr.cr_net_loss) AS total_return_loss
    FROM catalog_returns cr
    JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    WHERE r.r_reason_desc LIKE '%not%working%'
      AND cr.cr_returned_date_sk BETWEEN 2451545 AND 2451910
    GROUP BY i.i_item_sk, w.w_warehouse_sk
  ),
  web_returns_agg AS (
    SELECT
      i.i_item_sk,
      SUM(wr.wr_return_amt) AS web_return_amount,
      SUM(wr.wr_net_loss) AS web_return_loss
    FROM web_returns wr
    JOIN item i ON wr.wr_item_sk = i.i_item_sk
    JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
    WHERE r.r_reason_id = 'AAAAAAAAFAAAAAAA'
      AND wr.wr_returned_date_sk BETWEEN 2451545 AND 2451910
    GROUP BY i.i_item_sk
  ),
  inventory_agg AS (
    SELECT
      i.i_item_sk,
      w.w_warehouse_sk,
      SUM(inv.inv_quantity_on_hand) AS qty_on_hand
    FROM inventory inv
    JOIN item i ON inv.inv_item_sk = i.i_item_sk
    JOIN warehouse w ON inv.inv_warehouse_sk = w.w_warehouse_sk
    GROUP BY i.i_item_sk, w.w_warehouse_sk
  )
SELECT
  s.i_item_id,
  s.w_warehouse_name,
  s.call_center_name,
  s.total_sales,
  s.total_profit,
  COALESCE(r.total_returns, 0) AS total_returns,
  COALESCE(r.total_return_loss, 0) AS total_return_loss,
  COALESCE(wr.web_return_amount, 0) AS web_return_amount,
  COALESCE(wr.web_return_loss, 0) AS web_return_loss,
  COALESCE(iq.qty_on_hand, 0) AS quantity_on_hand,
  (s.total_profit - COALESCE(r.total_return_loss, 0) - COALESCE(wr.web_return_loss, 0)) AS adjusted_profit,
  (s.total_sales - COALESCE(r.total_returns, 0) - COALESCE(wr.web_return_amount, 0)) AS adjusted_sales
FROM sales_agg s
LEFT JOIN returns_agg r
  ON s.i_item_sk = r.i_item_sk
  AND s.w_warehouse_sk = r.w_warehouse_sk
LEFT JOIN web_returns_agg wr
  ON s.i_item_sk = wr.i_item_sk
LEFT JOIN inventory_agg iq
  ON s.i_item_sk = iq.i_item_sk
  AND s.w_warehouse_sk = iq.w_warehouse_sk
WHERE (s.total_profit - COALESCE(r.total_return_loss, 0) - COALESCE(wr.web_return_loss, 0)) > (
  SELECT AVG(total_profit) FROM sales_agg
)
ORDER BY adjusted_profit DESC
LIMIT 100
