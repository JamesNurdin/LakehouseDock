SELECT
    p.p_promo_name,
    r.r_reason_desc,
    COUNT(DISTINCT ws.ws_order_number) AS unique_web_orders,
    SUM(ws.ws_net_profit) AS total_web_profit,
    SUM(sr.sr_net_loss) AS total_store_returns_loss,
    SUM(cr.cr_net_loss) AS total_catalog_returns_loss,
    CASE WHEN SUM(ws.ws_net_profit) > 0 THEN 'Profitable' ELSE 'Loss' END AS profit_flag,
    (
        SELECT AVG(ws2.ws_net_profit)
        FROM web_sales ws2
        WHERE ws2.ws_promo_sk = p.p_promo_sk
    ) AS avg_promo_profit
FROM
    web_sales ws
    JOIN item i
        ON ws.ws_item_sk = i.i_item_sk
    JOIN customer c
        ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN promotion p
        ON ws.ws_promo_sk = p.p_promo_sk
    JOIN ship_mode sm
        ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN web_page wp
        ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN web_site wsite
        ON ws.ws_web_site_sk = wsite.web_site_sk
    JOIN time_dim td
        ON ws.ws_sold_time_sk = td.t_time_sk
    LEFT JOIN store_returns sr
        ON sr.sr_return_time_sk = td.t_time_sk
        AND sr.sr_item_sk = i.i_item_sk
    LEFT JOIN reason r
        ON sr.sr_reason_sk = r.r_reason_sk
    LEFT JOIN catalog_returns cr
        ON cr.cr_returned_time_sk = td.t_time_sk
        AND cr.cr_item_sk = i.i_item_sk
    LEFT JOIN call_center cc
        ON cr.cr_call_center_sk = cc.cc_call_center_sk
WHERE
    td.t_hour BETWEEN 9 AND 17
    AND wsite.web_country = 'USA'
    AND r.r_reason_desc = 'Package was damaged'
GROUP BY
    p.p_promo_name,
    p.p_promo_sk,
    r.r_reason_desc
ORDER BY
    total_web_profit DESC
