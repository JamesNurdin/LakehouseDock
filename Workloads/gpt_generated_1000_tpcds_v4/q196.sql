WITH promo_avg_discount AS (
    SELECT p.p_promo_sk,
           AVG(cs.cs_ext_discount_amt) AS avg_discount
    FROM promotion p
    JOIN catalog_sales cs ON cs.cs_promo_sk = p.p_promo_sk
    GROUP BY p.p_promo_sk
)
SELECT
    d.d_year,
    s.s_store_name,
    cp.cp_department,
    SUM(cs.cs_net_profit) AS total_catalog_profit,
    SUM(ws.ws_net_profit) AS total_web_profit,
    SUM(COALESCE(wr.wr_net_loss, 0)) AS total_returns_loss,
    CASE
        WHEN SUM(cs.cs_net_profit) + SUM(ws.ws_net_profit) > 100000 THEN 'HIGH'
        WHEN SUM(cs.cs_net_profit) + SUM(ws.ws_net_profit) >  50000 THEN 'MEDIUM'
        ELSE 'LOW'
    END AS profit_category,
    AVG(COALESCE(pad.avg_discount, 0)) AS avg_promo_discount
FROM date_dim d
-- join to catalog sales (sold date)
JOIN catalog_sales cs ON cs.cs_sold_date_sk = d.d_date_sk
-- join to web sales (sold date)
JOIN web_sales ws ON ws.ws_sold_date_sk = d.d_date_sk
-- left join returns (order number)
LEFT JOIN web_returns wr ON wr.wr_order_number = ws.ws_order_number
-- join to store (closed date)
JOIN store s ON s.s_closed_date_sk = d.d_date_sk
-- join to catalog page (catalog page key)
JOIN catalog_page cp ON cp.cp_catalog_page_sk = cs.cs_catalog_page_sk
-- join to ship mode (catalog sales ship mode)
JOIN ship_mode sm ON sm.sm_ship_mode_sk = cs.cs_ship_mode_sk
-- join to warehouse (catalog sales warehouse)
JOIN warehouse w ON w.w_warehouse_sk = cs.cs_warehouse_sk
-- join to promotion (catalog sales promo)
JOIN promotion p ON p.p_promo_sk = cs.cs_promo_sk
-- bring in average discount per promo from CTE
LEFT JOIN promo_avg_discount pad ON pad.p_promo_sk = p.p_promo_sk
-- join to call center (catalog sales call center)
JOIN call_center cc ON cc.cc_call_center_sk = cs.cs_call_center_sk
-- join customers twice under different aliases (bill and ship)
JOIN customer c_bill ON c_bill.c_customer_sk = cs.cs_bill_customer_sk
JOIN customer c_ship ON c_ship.c_customer_sk = cs.cs_ship_customer_sk
-- join customer demographics twice under different aliases (bill and ship)
JOIN customer_demographics cd_bill ON cd_bill.cd_demo_sk = cs.cs_bill_cdemo_sk
JOIN customer_demographics cd_ship ON cd_ship.cd_demo_sk = cs.cs_ship_cdemo_sk
-- join reason for returns
LEFT JOIN reason r ON r.r_reason_sk = wr.wr_reason_sk
-- join inventory for the same warehouse and date
JOIN inventory i ON i.inv_warehouse_sk = w.w_warehouse_sk
               AND i.inv_date_sk = d.d_date_sk
-- join web site for web sales
JOIN web_site wsit ON wsit.web_site_sk = ws.ws_web_site_sk
-- join time dimension for catalog sales time
JOIN time_dim td_cs ON td_cs.t_time_sk = cs.cs_sold_time_sk
-- join time dimension for web sales time (different alias)
JOIN time_dim td_ws ON td_ws.t_time_sk = ws.ws_sold_time_sk
WHERE d.d_year = 2001
  AND EXISTS (
        SELECT 1
        FROM inventory inv_sub
        WHERE inv_sub.inv_warehouse_sk = w.w_warehouse_sk
          AND inv_sub.inv_quantity_on_hand > 0
          AND inv_sub.inv_date_sk = d.d_date_sk
    )
GROUP BY d.d_year, s.s_store_name, cp.cp_department
ORDER BY total_catalog_profit DESC
LIMIT 100
