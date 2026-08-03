WITH sampled_sales AS (
    SELECT *
    FROM catalog_sales
    TABLESAMPLE BERNOULLI (10)
),
except_orders AS (
    SELECT cs_order_number
    FROM catalog_sales
    EXCEPT
    SELECT sr_ticket_number
    FROM store_returns
)
SELECT
    p.p_promo_name,
    sm.sm_type,
    t.t_hour,
    COUNT(DISTINCT cs.cs_order_number) AS order_cnt,
    SUM(cs.cs_net_profit) AS total_cs_profit,
    AVG(
        (SELECT SUM(ws2.ws_net_paid)
         FROM web_sales ws2
         WHERE ws2.ws_order_number = cs.cs_order_number)
    ) AS avg_ws_net_paid,
    CASE WHEN SUM(cs.cs_net_profit) > 10000 THEN 'HIGH' ELSE 'LOW' END AS profit_level
FROM sampled_sales cs
JOIN promotion p
  ON cs.cs_promo_sk = p.p_promo_sk
JOIN ship_mode sm
  ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN time_dim t
  ON cs.cs_sold_time_sk = t.t_time_sk
JOIN customer_demographics cd_bill
  ON cs.cs_bill_cdemo_sk = cd_bill.cd_demo_sk
JOIN household_demographics hd_bill
  ON cs.cs_bill_hdemo_sk = hd_bill.hd_demo_sk
JOIN customer_demographics cd_ship
  ON cs.cs_ship_cdemo_sk = cd_ship.cd_demo_sk
JOIN household_demographics hd_ship
  ON cs.cs_ship_hdemo_sk = hd_ship.hd_demo_sk
LEFT JOIN web_sales ws
  ON ws.ws_sold_time_sk = t.t_time_sk
LEFT JOIN web_page wp
  ON ws.ws_web_page_sk = wp.wp_web_page_sk
LEFT JOIN web_site wsite
  ON ws.ws_web_site_sk = wsite.web_site_sk
LEFT JOIN store_returns sr
  ON sr.sr_return_time_sk = t.t_time_sk
LEFT JOIN web_returns wr
  ON wr.wr_returned_time_sk = t.t_time_sk
WHERE cs.cs_order_number IN (SELECT cs_order_number FROM except_orders)
  AND EXISTS (
        SELECT 1
        FROM web_returns wr_exist
        WHERE wr_exist.wr_order_number = cs.cs_order_number
      )
GROUP BY CUBE (p.p_promo_name, sm.sm_type, t.t_hour)
ORDER BY total_cs_profit DESC
LIMIT 100
