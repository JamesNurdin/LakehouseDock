/*
Goal: Identify high‑profit orders that also have high‑loss returns, rank them by profit within each warehouse, and enrich the result with catalog, promotion, inventory, time, and web page details. The query joins all 13 selected tables using only the allowed join keys, applies multiple filters, uses a window function, includes a scalar correlated subquery, an anti‑join, an INTERSECT of two subqueries, a LEFT OUTER JOIN, and limits the output to the top 100 rows.
*/
WITH high_sales AS (
    SELECT cs.cs_order_number AS order_number
    FROM catalog_sales cs
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    WHERE p.p_discount_active = 'Y'
      AND cs.cs_net_profit > 500
),
high_returns AS (
    SELECT wr.wr_order_number AS order_number
    FROM web_returns wr
    WHERE wr.wr_net_loss > 200
      AND wr.wr_return_quantity > 1
),
intersect_orders AS (
    SELECT order_number FROM high_sales
    INTERSECT
    SELECT order_number FROM high_returns
)
SELECT
    cs.cs_order_number,
    cs.cs_net_profit,
    w.w_warehouse_name,
    w.w_state,
    cp.cp_department,
    sm.sm_type AS ship_mode_type,
    p.p_promo_name,
    i.inv_quantity_on_hand,
    t_cs.t_hour AS sold_hour,
    wp.wp_url,
    RANK() OVER (PARTITION BY w.w_warehouse_id ORDER BY cs.cs_net_profit DESC) AS profit_rank,
    (
        SELECT AVG(cs2.cs_net_profit)
        FROM catalog_sales cs2
        JOIN catalog_page cp2 ON cs2.cs_catalog_page_sk = cp2.cp_catalog_page_sk
        WHERE cp2.cp_department = cp.cp_department
    ) AS avg_dept_profit
FROM catalog_sales cs
JOIN time_dim t_cs
  ON cs.cs_sold_time_sk = t_cs.t_time_sk
JOIN customer c
  ON cs.cs_bill_customer_sk = c.c_customer_sk
JOIN household_demographics hd_bill
  ON cs.cs_bill_hdemo_sk = hd_bill.hd_demo_sk
JOIN income_band ib
  ON hd_bill.hd_income_band_sk = ib.ib_income_band_sk
JOIN catalog_page cp
  ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN ship_mode sm
  ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN warehouse w
  ON cs.cs_warehouse_sk = w.w_warehouse_sk
JOIN promotion p
  ON cs.cs_promo_sk = p.p_promo_sk
LEFT JOIN inventory i
  ON i.inv_warehouse_sk = w.w_warehouse_sk
JOIN web_sales ws
  ON ws.ws_warehouse_sk = w.w_warehouse_sk
 AND ws.ws_promo_sk = p.p_promo_sk
 AND ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
JOIN time_dim t_ws
  ON ws.ws_sold_time_sk = t_ws.t_time_sk
JOIN customer c_ws
  ON ws.ws_bill_customer_sk = c_ws.c_customer_sk
JOIN web_page wp
  ON ws.ws_web_page_sk = wp.wp_web_page_sk
JOIN web_returns wr
  ON wr.wr_item_sk = ws.ws_item_sk
 AND wr.wr_order_number = ws.ws_order_number
 AND wr.wr_web_page_sk = wp.wp_web_page_sk
JOIN time_dim t_ret
  ON wr.wr_returned_time_sk = t_ret.t_time_sk
WHERE cp.cp_department = 'Electronics'
  AND w.w_state = 'CA'
  AND p.p_discount_active = 'Y'
  AND (i.inv_quantity_on_hand > 0 OR i.inv_quantity_on_hand IS NULL)
  AND wp.wp_link_count > 10
  AND cs.cs_order_number IN (SELECT order_number FROM intersect_orders)
  AND NOT EXISTS (
        SELECT 1
        FROM promotion p2
        WHERE p2.p_promo_sk = cs.cs_promo_sk
          AND p2.p_channel_email = 'Y'
    )
ORDER BY profit_rank, cs.cs_net_profit DESC
LIMIT 100
