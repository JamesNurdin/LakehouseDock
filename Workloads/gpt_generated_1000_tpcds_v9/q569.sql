WITH aggregated_sales AS (
    SELECT
        p.p_promo_id AS p_promo_id,
        sm.sm_type AS sm_type,
        td_cs.t_hour AS t_hour,
        SUM(cs.cs_net_paid_inc_ship) AS catalog_sales_net,
        SUM(ws.ws_net_paid_inc_ship) AS web_sales_net,
        SUM(cr.cr_net_loss) AS catalog_returns_loss,
        SUM(sr.sr_net_loss) AS store_returns_loss,
        SUM(wr.wr_net_loss) AS web_returns_loss,
        COUNT(DISTINCT cs.cs_order_number) AS catalog_orders,
        COUNT(DISTINCT ws.ws_order_number) AS web_orders
    FROM catalog_sales cs
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
    JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    JOIN time_dim td_cs ON cs.cs_sold_time_sk = td_cs.t_time_sk
    LEFT JOIN catalog_returns cr ON cs.cs_order_number = cr.cr_order_number AND cs.cs_item_sk = cr.cr_item_sk
    LEFT JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    LEFT JOIN store_returns sr ON sr.sr_customer_sk = c.c_customer_sk
        AND sr.sr_cdemo_sk = cd.cd_demo_sk
        AND sr.sr_hdemo_sk = hd.hd_demo_sk
        AND sr.sr_addr_sk = ca.ca_address_sk
        AND sr.sr_reason_sk = r.r_reason_sk
    LEFT JOIN time_dim td_sr ON sr.sr_return_time_sk = td_sr.t_time_sk
    LEFT JOIN web_sales ws ON ws.ws_promo_sk = p.p_promo_sk
        AND ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
        AND ws.ws_bill_customer_sk = c.c_customer_sk
    LEFT JOIN time_dim td_ws ON ws.ws_sold_time_sk = td_ws.t_time_sk
    LEFT JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    LEFT JOIN web_site wsite ON ws.ws_web_site_sk = wsite.web_site_sk
    LEFT JOIN web_returns wr ON wr.wr_order_number = ws.ws_order_number
        AND wr.wr_item_sk = ws.ws_item_sk
        AND wr.wr_web_page_sk = wp.wp_web_page_sk
    LEFT JOIN time_dim td_wr ON wr.wr_returned_time_sk = td_wr.t_time_sk
    LEFT JOIN reason r2 ON wr.wr_reason_sk = r2.r_reason_sk
    WHERE
        cc.cc_country = 'United States'
        AND p.p_discount_active = 'Y'
        AND sm.sm_carrier = 'UPS'
        AND ca.ca_gmt_offset = -8.00
        AND td_cs.t_hour BETWEEN 9 AND 17
        AND cs.cs_net_paid_inc_ship > 1000
    GROUP BY
        p.p_promo_id,
        sm.sm_type,
        td_cs.t_hour
)
SELECT
    a.p_promo_id,
    a.sm_type,
    a.t_hour,
    a.catalog_sales_net,
    a.web_sales_net,
    a.catalog_returns_loss,
    a.store_returns_loss,
    a.web_returns_loss,
    (a.catalog_sales_net + a.web_sales_net) - (a.catalog_returns_loss + a.store_returns_loss + a.web_returns_loss) AS net_profit,
    (
        SELECT SUM(cs.cs_net_paid_inc_ship)
        FROM catalog_sales cs
        JOIN promotion p2 ON cs.cs_promo_sk = p2.p_promo_sk
        WHERE p2.p_promo_id = a.p_promo_id
    ) AS total_catalog_sales_for_promo
FROM aggregated_sales a
WHERE (a.catalog_sales_net + a.web_sales_net) > (
    SELECT AVG(b.catalog_sales_net + b.web_sales_net)
    FROM aggregated_sales b
    WHERE b.p_promo_id = a.p_promo_id
)
ORDER BY net_profit DESC
LIMIT 100
