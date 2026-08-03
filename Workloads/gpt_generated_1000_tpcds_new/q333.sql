WITH
  ss_agg AS (
    SELECT
      ss.ss_store_sk,
      ss.ss_sold_date_sk,
      ss.ss_promo_sk,
      SUM(ss.ss_ext_sales_price) AS store_sales_amount,
      SUM(ss.ss_net_profit)      AS store_profit
    FROM store_sales ss
    GROUP BY ss.ss_store_sk, ss.ss_sold_date_sk, ss.ss_promo_sk
  ),
  ws_agg AS (
    SELECT
      ws.ws_warehouse_sk,
      ws.ws_sold_date_sk,
      ws.ws_promo_sk,
      SUM(ws.ws_ext_sales_price) AS web_sales_amount,
      SUM(ws.ws_net_profit)      AS web_profit
    FROM web_sales ws
    GROUP BY ws.ws_warehouse_sk, ws.ws_sold_date_sk, ws.ws_promo_sk
  ),
  cr_agg AS (
    SELECT
      cr.cr_warehouse_sk,
      cr.cr_returned_date_sk,
      SUM(cr.cr_return_amount) AS return_amount,
      SUM(cr.cr_net_loss)      AS net_loss
    FROM catalog_returns cr
    GROUP BY cr.cr_warehouse_sk, cr.cr_returned_date_sk
  ),
  inv_agg AS (
    SELECT
      i.inv_warehouse_sk,
      i.inv_date_sk,
      SUM(i.inv_quantity_on_hand) AS qty_on_hand
    FROM inventory i
    GROUP BY i.inv_warehouse_sk, i.inv_date_sk
  )
SELECT
  d_sales.d_date              AS sales_date,
  d_returns.d_date            AS return_date,
  d_inv.d_date                AS inventory_date,
  w_cr.w_warehouse_name       AS return_warehouse,
  w_ws.w_warehouse_name       AS web_warehouse,
  s.s_store_name,
  p.p_promo_name,
  ss_agg.store_sales_amount,
  ws_agg.web_sales_amount,
  cr_agg.return_amount,
  inv_agg.qty_on_hand,
  ROW_NUMBER() OVER (ORDER BY ss_agg.store_sales_amount DESC) AS sales_rank
FROM ss_agg
FULL OUTER JOIN store s
  ON ss_agg.ss_store_sk = s.s_store_sk
LEFT JOIN promotion p
  ON ss_agg.ss_promo_sk = p.p_promo_sk
LEFT JOIN date_dim d_sales
  ON ss_agg.ss_sold_date_sk = d_sales.d_date_sk
LEFT JOIN ws_agg
  ON ss_agg.ss_sold_date_sk = ws_agg.ws_sold_date_sk
  AND ss_agg.ss_promo_sk   = ws_agg.ws_promo_sk
LEFT JOIN date_dim d_ws_sold
  ON ws_agg.ws_sold_date_sk = d_ws_sold.d_date_sk
LEFT JOIN warehouse w_ws
  ON ws_agg.ws_warehouse_sk = w_ws.w_warehouse_sk
LEFT JOIN cr_agg
  ON cr_agg.cr_returned_date_sk = d_sales.d_date_sk
LEFT JOIN date_dim d_returns
  ON cr_agg.cr_returned_date_sk = d_returns.d_date_sk
LEFT JOIN warehouse w_cr
  ON cr_agg.cr_warehouse_sk = w_cr.w_warehouse_sk
LEFT JOIN inv_agg
  ON inv_agg.inv_date_sk = d_sales.d_date_sk
LEFT JOIN date_dim d_inv
  ON inv_agg.inv_date_sk = d_inv.d_date_sk
LEFT JOIN warehouse w_inv
  ON inv_agg.inv_warehouse_sk = w_inv.w_warehouse_sk
LEFT JOIN date_dim d_store_closed
  ON s.s_closed_date_sk = d_store_closed.d_date_sk
LEFT JOIN date_dim d_promo_start
  ON p.p_start_date_sk = d_promo_start.d_date_sk
LEFT JOIN date_dim d_promo_end
  ON p.p_end_date_sk = d_promo_end.d_date_sk
ORDER BY ss_agg.store_sales_amount DESC
LIMIT 100
