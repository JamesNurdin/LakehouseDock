WITH active_promo AS (
    SELECT p_promo_sk
    FROM promotion
    WHERE p_discount_active = 'Y'
),
sales_promo AS (
    SELECT DISTINCT ws_promo_sk AS p_promo_sk
    FROM web_sales
),
promo_common AS (
    SELECT p_promo_sk FROM active_promo
    INTERSECT
    SELECT p_promo_sk FROM sales_promo
)
SELECT
    p.p_promo_id,
    i.i_item_id,
    ws_site.web_name,
    sm.sm_type,
    SUM(ws.ws_net_profit) AS total_net_profit,
    SUM(COALESCE(sr.sr_net_loss, 0) + COALESCE(cr.cr_net_loss, 0) + COALESCE(wr.wr_net_loss, 0)) AS total_return_loss,
    CASE
        WHEN SUM(ws.ws_net_profit) - SUM(COALESCE(sr.sr_net_loss, 0) + COALESCE(cr.cr_net_loss, 0) + COALESCE(wr.wr_net_loss, 0)) > 10000 THEN 'HIGH'
        ELSE 'LOW'
    END AS profit_flag,
    ROW_NUMBER() OVER (PARTITION BY p.p_promo_id ORDER BY (SUM(ws.ws_net_profit) - SUM(COALESCE(sr.sr_net_loss, 0) + COALESCE(cr.cr_net_loss, 0) + COALESCE(wr.wr_net_loss, 0))) DESC) AS rn,
    (SELECT AVG(i2.i_current_price) FROM item i2) AS overall_avg_price
FROM
    web_sales ws
JOIN time_dim td ON ws.ws_sold_time_sk = td.t_time_sk
JOIN item i ON ws.ws_item_sk = i.i_item_sk
JOIN customer_address ca_bill ON ws.ws_bill_addr_sk = ca_bill.ca_address_sk
JOIN customer_address ca_ship ON ws.ws_ship_addr_sk = ca_ship.ca_address_sk
JOIN web_site ws_site ON ws.ws_web_site_sk = ws_site.web_site_sk
JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
JOIN promo_common pc ON p.p_promo_sk = pc.p_promo_sk
LEFT JOIN store_returns sr ON sr.sr_item_sk = i.i_item_sk
LEFT JOIN store s ON sr.sr_store_sk = s.s_store_sk
LEFT JOIN reason r_sr ON sr.sr_reason_sk = r_sr.r_reason_sk
LEFT JOIN catalog_returns cr ON cr.cr_item_sk = i.i_item_sk
LEFT JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
LEFT JOIN ship_mode sm_cr ON cr.cr_ship_mode_sk = sm_cr.sm_ship_mode_sk
LEFT JOIN warehouse w_cr ON cr.cr_warehouse_sk = w_cr.w_warehouse_sk
LEFT JOIN reason r_cr ON cr.cr_reason_sk = r_cr.r_reason_sk
LEFT JOIN web_returns wr ON wr.wr_item_sk = i.i_item_sk AND wr.wr_order_number = ws.ws_order_number
LEFT JOIN reason r_wr ON wr.wr_reason_sk = r_wr.r_reason_sk
WHERE
    p.p_start_date_sk BETWEEN 2450150 AND 2450500
    AND i.i_current_price > 20
    AND sm.sm_type = 'OVERNIGHT'
    AND w.w_state = 'CA'
    AND cc.cc_state = 'CA'
    AND ws_site.web_country = 'United States'
    AND td.t_hour BETWEEN 8 AND 18
GROUP BY
    p.p_promo_id,
    i.i_item_id,
    ws_site.web_name,
    sm.sm_type
HAVING
    SUM(ws.ws_net_profit) > 0
ORDER BY
    total_net_profit DESC,
    profit_flag DESC
LIMIT 100
