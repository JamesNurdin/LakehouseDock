WITH
  intersect_orders AS (
    SELECT cs.cs_order_number AS order_number
    FROM catalog_sales cs
    WHERE cs.cs_quantity > 5
    INTERSECT
    SELECT ws.ws_order_number
    FROM web_sales ws
    WHERE ws.ws_quantity > 5
  ),
  base AS (
    SELECT
      i.i_item_sk,
      i.i_category,
      i.i_category_id,
      w.w_warehouse_name,
      sm.sm_type AS ship_mode_type,
      p.p_promo_name,
      wp.wp_web_page_id,
      web.web_site_id,
      td_cs.t_hour,
      SUM(cs.cs_net_paid_inc_tax)                         AS sum_catalog_net,
      SUM(ws.ws_net_paid_inc_tax)                         AS sum_web_net,
      SUM(ss.ss_net_paid_inc_tax)                         AS sum_store_net,
      SUM(cr.cr_return_amount)                            AS sum_returns,
      CASE WHEN SUM(cs.cs_net_paid_inc_tax) > 10000 THEN 'High' ELSE 'Low' END AS profit_level,
      (
        SELECT SUM(p2.p_cost)
        FROM promotion p2
        WHERE p2.p_item_sk = i.i_item_sk
      )                                                   AS total_promo_cost
    FROM catalog_sales cs
    JOIN catalog_page cp
      ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN catalog_returns cr
      ON cr.cr_order_number = cs.cs_order_number
    JOIN item i
      ON cs.cs_item_sk = i.i_item_sk
    JOIN promotion p
      ON cs.cs_promo_sk = p.p_promo_sk
    JOIN ship_mode sm
      ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w
      ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN time_dim td_cs
      ON cs.cs_sold_time_sk = td_cs.t_time_sk
    JOIN web_sales ws
      ON ws.ws_order_number = cs.cs_order_number
    JOIN web_page wp
      ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN web_site web
      ON ws.ws_web_site_sk = web.web_site_sk
    JOIN ship_mode sm_ws
      ON ws.ws_ship_mode_sk = sm_ws.sm_ship_mode_sk
    JOIN warehouse w_ws
      ON ws.ws_warehouse_sk = w_ws.w_warehouse_sk
    JOIN promotion p_ws
      ON ws.ws_promo_sk = p_ws.p_promo_sk
    JOIN time_dim td_ws
      ON ws.ws_sold_time_sk = td_ws.t_time_sk
    JOIN store_sales ss
      ON ss.ss_item_sk = i.i_item_sk
     AND ss.ss_sold_time_sk = td_cs.t_time_sk
    JOIN time_dim td_ss
      ON ss.ss_sold_time_sk = td_ss.t_time_sk
    WHERE wp.wp_rec_end_date > DATE '2000-01-01'
      AND p.p_channel_dmail = 'Y'
      AND i.i_units = 'Carton'
      AND td_cs.t_hour = 12
      AND EXISTS (SELECT 1 FROM intersect_orders io WHERE io.order_number = cs.cs_order_number)
    GROUP BY
      i.i_item_sk,
      i.i_category,
      i.i_category_id,
      w.w_warehouse_name,
      sm.sm_type,
      p.p_promo_name,
      wp.wp_web_page_id,
      web.web_site_id,
      td_cs.t_hour,
      i.i_item_sk
  )
SELECT
  i_category,
  i_category_id,
  profit_level,
  SUM(sum_catalog_net) AS total_catalog_net,
  AVG(total_promo_cost) AS avg_promo_cost,
  COUNT(*) AS num_items
FROM base
WHERE total_promo_cost IS NOT NULL
GROUP BY i_category, i_category_id, profit_level
HAVING SUM(sum_catalog_net) > 50000
ORDER BY total_catalog_net DESC
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY
