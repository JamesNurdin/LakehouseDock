WITH cs_agg AS (
   SELECT
      i.i_item_sk,
      i.i_category,
      d_cs.d_date,
      SUM(cs.cs_net_profit) AS net_profit,
      SUM(cs.cs_quantity) AS total_quantity
   FROM catalog_sales cs
   INNER JOIN date_dim d_cs ON cs.cs_sold_date_sk = d_cs.d_date_sk
   INNER JOIN time_dim t_cs ON cs.cs_sold_time_sk = t_cs.t_time_sk
   INNER JOIN item i ON cs.cs_item_sk = i.i_item_sk
   INNER JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
   INNER JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
   INNER JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
   INNER JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
   INNER JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
   INNER JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
   INNER JOIN inventory inv ON i.i_item_sk = inv.inv_item_sk
      AND inv.inv_warehouse_sk = w.w_warehouse_sk
      AND inv.inv_date_sk = d_cs.d_date_sk
   INNER JOIN store st ON st.s_closed_date_sk = d_cs.d_date_sk
   WHERE d_cs.d_year = 2001
     AND sm.sm_code IN ('AIR', 'SEA')
     AND i.i_category = 'Sports'
     AND p.p_discount_active = 'Y'
     AND cs.cs_quantity > 5
     AND EXISTS (
        SELECT 1 FROM inventory inv2
        WHERE inv2.inv_item_sk = cs.cs_item_sk
          AND inv2.inv_quantity_on_hand > 500
     )
   GROUP BY i.i_item_sk, i.i_category, d_cs.d_date
),
ws_agg AS (
   SELECT
      i.i_item_sk,
      i.i_category,
      d_ws.d_date,
      SUM(ws.ws_net_profit) AS net_profit,
      SUM(ws.ws_quantity) AS total_quantity
   FROM web_sales ws
   INNER JOIN date_dim d_ws ON ws.ws_sold_date_sk = d_ws.d_date_sk
   INNER JOIN time_dim t_ws ON ws.ws_sold_time_sk = t_ws.t_time_sk
   INNER JOIN item i ON ws.ws_item_sk = i.i_item_sk
   INNER JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
   INNER JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
   INNER JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
   INNER JOIN web_site we ON ws.ws_web_site_sk = we.web_site_sk
   INNER JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
   INNER JOIN inventory inv ON i.i_item_sk = inv.inv_item_sk
      AND inv.inv_warehouse_sk = w.w_warehouse_sk
      AND inv.inv_date_sk = d_ws.d_date_sk
   INNER JOIN store st ON st.s_closed_date_sk = d_ws.d_date_sk
   WHERE d_ws.d_year = 2001
     AND sm.sm_code IN ('AIR', 'SEA')
     AND i.i_category = 'Sports'
     AND p.p_discount_active = 'Y'
     AND ws.ws_quantity > 5
   GROUP BY i.i_item_sk, i.i_category, d_ws.d_date
),
combined AS (
   SELECT i_item_sk, i_category, d_date, net_profit, total_quantity FROM cs_agg
   UNION ALL
   SELECT i_item_sk, i_category, d_date, net_profit, total_quantity FROM ws_agg
),
agg AS (
   SELECT i_category,
          d_date,
          SUM(net_profit) AS total_net_profit,
          SUM(total_quantity) AS total_quantity
   FROM combined
   GROUP BY i_category, d_date
   HAVING SUM(net_profit) > 1000
)
SELECT
   i_category,
   d_date,
   total_net_profit,
   total_quantity,
   SUM(total_net_profit) OVER (PARTITION BY i_category ORDER BY d_date ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_net_profit
FROM agg
ORDER BY i_category, d_date DESC
LIMIT 100
