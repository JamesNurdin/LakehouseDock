WITH
  ws_base AS (
    SELECT
      ws.ws_order_number,
      ws.ws_sold_date_sk,
      ws.ws_item_sk,
      ws.ws_warehouse_sk,
      ws.ws_promo_sk,
      ws.ws_quantity,
      ws.ws_net_paid,
      ws.ws_net_profit,
      ws.ws_web_page_sk,
      ws.ws_bill_cdemo_sk,
      ws.ws_bill_hdemo_sk
    FROM web_sales ws
  ),
  cr_agg AS (
    SELECT
      cr.cr_item_sk,
      cr.cr_returned_date_sk,
      SUM(cr.cr_return_amount)          AS total_cr_return_amount,
      SUM(cr.cr_return_quantity)        AS total_cr_return_qty
    FROM catalog_returns cr
    GROUP BY cr.cr_item_sk, cr.cr_returned_date_sk
  ),
  wr_agg AS (
    SELECT
      wr.wr_order_number,
      SUM(wr.wr_return_amt)            AS total_wr_return_amount,
      SUM(wr.wr_return_quantity)       AS total_wr_return_qty
    FROM web_returns wr
    GROUP BY wr.wr_order_number
  ),
  inv_agg AS (
    SELECT
      inv.inv_item_sk,
      inv.inv_warehouse_sk,
      SUM(inv.inv_quantity_on_hand)     AS total_inventory_qty
    FROM inventory inv
    GROUP BY inv.inv_item_sk, inv.inv_warehouse_sk
  )
SELECT
  d_sold.d_year                                      AS year,
  w.w_state                                          AS warehouse_state,
  p.p_purpose                                        AS promo_purpose,
  COUNT(DISTINCT ws.ws_order_number)                AS total_orders,
  SUM(ws.ws_net_paid)                               AS total_net_paid,
  SUM(ws.ws_net_profit)                             AS total_net_profit,
  AVG(i.i_current_price)                            AS avg_item_price,
  COALESCE(SUM(cr_agg.total_cr_return_amount), 0)   AS total_catalog_return_amount,
  COALESCE(SUM(wr_agg.total_wr_return_amount), 0)   AS total_web_return_amount,
  COALESCE(SUM(inv_agg.total_inventory_qty), 0)     AS total_inventory_qty
FROM ws_base ws
JOIN item i                     ON ws.ws_item_sk = i.i_item_sk
JOIN warehouse w                 ON ws.ws_warehouse_sk = w.w_warehouse_sk
JOIN promotion p                 ON ws.ws_promo_sk = p.p_promo_sk
JOIN date_dim d_sold            ON ws.ws_sold_date_sk = d_sold.d_date_sk
JOIN web_page wp                ON ws.ws_web_page_sk = wp.wp_web_page_sk
LEFT JOIN store s               ON s.s_closed_date_sk = d_sold.d_date_sk
LEFT JOIN catalog_returns cr    ON cr.cr_item_sk = i.i_item_sk
LEFT JOIN catalog_page cp       ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
LEFT JOIN call_center cc        ON cr.cr_call_center_sk = cc.cc_call_center_sk
LEFT JOIN cr_agg                ON cr.cr_item_sk = cr_agg.cr_item_sk
                                 AND cr.cr_returned_date_sk = cr_agg.cr_returned_date_sk
LEFT JOIN web_returns wr        ON wr.wr_order_number = ws.ws_order_number
LEFT JOIN wr_agg                ON wr.wr_order_number = wr_agg.wr_order_number
LEFT JOIN inv_agg               ON i.i_item_sk = inv_agg.inv_item_sk
                                 AND w.w_warehouse_sk = inv_agg.inv_warehouse_sk
WHERE d_sold.d_year = 2001
  AND i.i_brand = 'Brand#23'
  AND w.w_state = 'CA'
  AND cc.cc_country = 'United States'
  AND p.p_purpose = 'Clearance'
  AND cp.cp_type = 'A'
GROUP BY d_sold.d_year, w.w_state, p.p_purpose
ORDER BY total_net_paid DESC
LIMIT 100
