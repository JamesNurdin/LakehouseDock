WITH
  sales_agg AS (
    SELECT
      ws.ws_warehouse_sk,
      ws.ws_promo_sk,
      ws.ws_web_site_sk,
      ws.ws_order_number,
      ws.ws_item_sk,
      SUM(ws.ws_net_paid_inc_ship_tax) AS total_sales,
      SUM(ws.ws_quantity) AS total_qty,
      ROW_NUMBER() OVER (PARTITION BY ws.ws_warehouse_sk ORDER BY SUM(ws.ws_net_paid_inc_ship_tax) DESC) AS warehouse_sales_rank
    FROM web_sales ws
    GROUP BY
      ws.ws_warehouse_sk,
      ws.ws_promo_sk,
      ws.ws_web_site_sk,
      ws.ws_order_number,
      ws.ws_item_sk
  ),
  promo_agg AS (
    SELECT p.p_promo_sk, MAX(p.p_cost) AS max_cost
    FROM promotion p
    GROUP BY p.p_promo_sk
  ),
  union_dim AS (
    SELECT 'promotion' AS src,
           CAST(p.p_promo_id AS VARCHAR) AS key_id,
           CAST(p.p_cost AS DOUBLE) AS metric
    FROM promotion p
    WHERE p.p_cost > 100
    UNION ALL
    SELECT 'warehouse' AS src,
           CAST(w.w_warehouse_id AS VARCHAR) AS key_id,
           CAST(w.w_warehouse_sq_ft AS DOUBLE) AS metric
    FROM warehouse w
    WHERE w.w_warehouse_sq_ft > 600000
  )
SELECT
  w.w_warehouse_name,
  s.total_sales,
  s.total_qty,
  p.p_promo_name,
  ws_site.web_name,
  ud.src,
  ud.key_id,
  ud.metric,
  (SELECT MAX(p2.p_cost) FROM promotion p2 WHERE p2.p_promo_id = p.p_promo_id) AS max_promo_cost,
  s.warehouse_sales_rank
FROM sales_agg s
JOIN warehouse w ON s.ws_warehouse_sk = w.w_warehouse_sk
JOIN promotion p ON s.ws_promo_sk = p.p_promo_sk
JOIN web_site ws_site ON s.ws_web_site_sk = ws_site.web_site_sk
JOIN web_returns wr ON wr.wr_order_number = s.ws_order_number AND wr.wr_item_sk = s.ws_item_sk
JOIN promotion p_alias1 ON s.ws_promo_sk = p_alias1.p_promo_sk
JOIN warehouse w_alias1 ON s.ws_warehouse_sk = w_alias1.w_warehouse_sk
JOIN promotion p_alias2 ON s.ws_promo_sk = p_alias2.p_promo_sk
JOIN warehouse w_alias2 ON s.ws_warehouse_sk = w_alias2.w_warehouse_sk
JOIN web_returns wr_alias1 ON wr_alias1.wr_order_number = s.ws_order_number AND wr_alias1.wr_item_sk = s.ws_item_sk
LEFT JOIN union_dim ud ON ud.key_id = p.p_promo_id OR ud.key_id = w.w_warehouse_id
WHERE EXISTS (
  SELECT 1
  FROM web_returns wr_exists
  WHERE wr_exists.wr_order_number = s.ws_order_number
    AND wr_exists.wr_return_quantity > 0
)
ORDER BY s.total_sales DESC
LIMIT 100
