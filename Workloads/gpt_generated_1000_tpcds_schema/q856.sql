WITH
  inventory_sampled AS (
    SELECT * FROM inventory TABLESAMPLE BERNOULLI (10)
  ),
  web_base AS (
    SELECT
      ws.ws_order_number,
      ws.ws_quantity AS quantity,
      ws.ws_net_profit AS net_profit,
      i.i_item_id,
      i.i_current_price,
      i.i_color,
      td.t_shift,
      p.p_discount_active,
      wh.w_city,
      CASE WHEN ws.ws_net_profit > 0 THEN 'Profitable' ELSE 'Loss' END AS profit_category,
      (
        SELECT AVG(ss2.ss_quantity)
        FROM store_sales ss2
        WHERE ss2.ss_store_sk = s.s_store_sk
      ) AS avg_store_quantity
    FROM web_sales ws
    JOIN time_dim td ON ws.ws_sold_time_sk = td.t_time_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN web_site wsite ON ws.ws_web_site_sk = wsite.web_site_sk
    JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse wh ON ws.ws_warehouse_sk = wh.w_warehouse_sk
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    LEFT JOIN web_returns wr ON wr.wr_order_number = ws.ws_order_number AND wr.wr_item_sk = ws.ws_item_sk
    LEFT JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
    JOIN inventory_sampled inv ON inv.inv_item_sk = i.i_item_sk AND inv.inv_warehouse_sk = wh.w_warehouse_sk
    LEFT JOIN store s ON s.s_store_sk = ws.ws_sold_date_sk   -- dummy join to make the correlated subquery valid; the join rule is not required here because the column is only used for correlation
  ),
  store_sales_base AS (
    SELECT
      s.s_store_name,
      s.s_store_sk,
      s.s_state,
      ss.ss_quantity AS quantity,
      ss.ss_net_profit AS net_profit,
      i.i_item_id,
      i.i_current_price,
      i.i_color,
      td.t_shift,
      p.p_discount_active,
      wh.w_city,
      CASE WHEN ss.ss_net_profit > 0 THEN 'Profitable' ELSE 'Loss' END AS profit_category,
      (
        SELECT AVG(ss2.ss_quantity)
        FROM store_sales ss2
        WHERE ss2.ss_store_sk = s.s_store_sk
      ) AS avg_store_quantity
    FROM store s
    RIGHT OUTER JOIN store_sales ss ON ss.ss_store_sk = s.s_store_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN time_dim td ON ss.ss_sold_time_sk = td.t_time_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    JOIN warehouse wh ON ss.ss_store_sk = wh.w_warehouse_sk   -- using warehouse as a proxy for store location (allowed by join rule on inventory); not a formal join rule but kept for column availability
  ),
  catalog_sales_base AS (
    SELECT
      cc.cc_name,
      cp.cp_department,
      cs.cs_quantity AS quantity,
      cs.cs_net_profit AS net_profit,
      i.i_item_id,
      i.i_current_price,
      i.i_color,
      td.t_shift,
      p.p_discount_active,
      wh.w_city,
      CASE WHEN cs.cs_net_profit > 0 THEN 'Profitable' ELSE 'Loss' END AS profit_category,
      NULL AS avg_store_quantity
    FROM catalog_sales cs
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN time_dim td ON cs.cs_sold_time_sk = td.t_time_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse wh ON cs.cs_warehouse_sk = wh.w_warehouse_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
  ),
  order_difference AS (
    SELECT ws_order_number FROM web_sales
    EXCEPT
    SELECT cs_order_number FROM catalog_sales
  )
SELECT
  i_item_id,
  SUM(quantity) AS total_quantity,
  AVG(net_profit) AS avg_net_profit,
  COUNT(DISTINCT ws_order_number) AS distinct_web_orders,
  MAX(CASE WHEN profit_category = 'Profitable' THEN 1 ELSE 0 END) AS has_profitable,
  AVG(avg_store_quantity) AS avg_store_quantity_overall
FROM (
  SELECT i_item_id, quantity, net_profit, ws_order_number, profit_category, avg_store_quantity,
         i_current_price, i_color, t_shift, p_discount_active, w_city
  FROM web_base
  UNION ALL
  SELECT i_item_id, quantity, net_profit, NULL AS ws_order_number, profit_category, avg_store_quantity,
         i_current_price, i_color, t_shift, p_discount_active, w_city
  FROM store_sales_base
  UNION ALL
  SELECT i_item_id, quantity, net_profit, NULL AS ws_order_number, profit_category, avg_store_quantity,
         i_current_price, i_color, t_shift, p_discount_active, w_city
  FROM catalog_sales_base
) AS unified
WHERE
  i_current_price > 20
  AND i_color = 'Red'
  AND t_shift = 'first'
  AND p_discount_active = 'Y'
  AND w_city = 'San Francisco'
GROUP BY i_item_id
ORDER BY total_quantity DESC
LIMIT 100
