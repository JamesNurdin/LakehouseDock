WITH avg_active_promo AS (
    SELECT AVG(p2.p_cost) AS avg_cost
    FROM promotion p2
    WHERE p2.p_discount_active = 'Y'
)
SELECT
    cc.cc_name,
    cp.cp_department,
    td_cs.t_hour,
    SUM(cs.cs_net_profit) AS total_catalog_profit,
    SUM(ws.ws_net_profit) AS total_web_profit,
    SUM(sr.sr_net_loss) AS total_store_return_loss,
    SUM(wr.wr_net_loss) AS total_web_return_loss,
    COUNT(DISTINCT cs.cs_order_number) AS catalog_orders,
    COUNT(DISTINCT ws.ws_order_number) AS web_orders,
    (SELECT avg_cost FROM avg_active_promo) AS avg_active_promo_cost
FROM catalog_sales cs
JOIN call_center cc
  ON cs.cs_call_center_sk = cc.cc_call_center_sk
JOIN catalog_page cp
  ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN promotion p
  ON cs.cs_promo_sk = p.p_promo_sk
JOIN time_dim td_cs
  ON cs.cs_sold_time_sk = td_cs.t_time_sk
JOIN customer_demographics cd_bill
  ON cs.cs_bill_cdemo_sk = cd_bill.cd_demo_sk
JOIN customer_demographics cd_ship
  ON cs.cs_ship_cdemo_sk = cd_ship.cd_demo_sk
JOIN web_sales ws
  ON ws.ws_promo_sk = p.p_promo_sk
JOIN web_site ws_site
  ON ws.ws_web_site_sk = ws_site.web_site_sk
JOIN time_dim td_ws
  ON ws.ws_sold_time_sk = td_ws.t_time_sk
JOIN web_returns wr
  ON wr.wr_order_number = ws.ws_order_number
 AND wr.wr_item_sk = ws.ws_item_sk
JOIN time_dim td_wr
  ON wr.wr_returned_time_sk = td_wr.t_time_sk
JOIN reason r_wr
  ON wr.wr_reason_sk = r_wr.r_reason_sk
JOIN customer_demographics cd_wr_refunded
  ON wr.wr_refunded_cdemo_sk = cd_wr_refunded.cd_demo_sk
JOIN customer_demographics cd_wr_returning
  ON wr.wr_returning_cdemo_sk = cd_wr_returning.cd_demo_sk
JOIN store_returns sr
  ON sr.sr_return_time_sk = td_cs.t_time_sk
JOIN customer_demographics cd_sr
  ON sr.sr_cdemo_sk = cd_sr.cd_demo_sk
JOIN reason r_sr
  ON sr.sr_reason_sk = r_sr.r_reason_sk
WHERE td_cs.t_hour BETWEEN 8 AND 18
  AND EXISTS (
        SELECT 1
        FROM reason r_filter
        WHERE r_filter.r_reason_sk = sr.sr_reason_sk
          AND r_filter.r_reason_desc LIKE '%damage%'
    )
GROUP BY cc.cc_name, cp.cp_department, td_cs.t_hour
HAVING SUM(cs.cs_net_profit) > 1000
   AND SUM(ws.ws_net_profit) > 500
LIMIT 100
