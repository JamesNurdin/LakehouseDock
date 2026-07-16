SELECT
    p.p_promo_id,
    sm.sm_ship_mode_id,
    wsit.web_country,
    SUM(cs.cs_net_profit) AS catalog_net_profit,
    SUM(ws.ws_net_profit) AS web_net_profit,
    SUM(cs.cs_net_profit) + SUM(ws.ws_net_profit) AS total_net_profit,
    COUNT(DISTINCT cs.cs_order_number) AS catalog_orders,
    COUNT(DISTINCT ws.ws_order_number) AS web_orders,
    AVG(cs.cs_ext_discount_amt) AS avg_catalog_discount,
    AVG(ws.ws_ext_discount_amt) AS avg_web_discount,
    SUM(cs.cs_quantity) AS catalog_quantity,
    SUM(ws.ws_quantity) AS web_quantity
FROM
    catalog_sales cs
JOIN
    promotion p ON cs.cs_promo_sk = p.p_promo_sk
JOIN
    ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN
    web_sales ws ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk AND ws.ws_promo_sk = p.p_promo_sk
JOIN
    web_site wsit ON ws.ws_web_site_sk = wsit.web_site_sk
WHERE
    cs.cs_ext_discount_amt > 500
    AND ws.ws_ext_discount_amt > 200
    AND p.p_start_date_sk >= 2450000
    AND sm.sm_type = 'AIR'
    AND wsit.web_state = 'CA'
GROUP BY
    p.p_promo_id,
    sm.sm_ship_mode_id,
    wsit.web_country
HAVING
    SUM(cs.cs_net_profit) + SUM(ws.ws_net_profit) > 1000
ORDER BY
    total_net_profit DESC
LIMIT 100
