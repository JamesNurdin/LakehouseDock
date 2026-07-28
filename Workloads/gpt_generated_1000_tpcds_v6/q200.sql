WITH max_price AS (
    SELECT MAX(i_current_price) AS mx_price
    FROM item
    WHERE i_brand = 'Brand#12'
)
SELECT
    s.s_store_id,
    d_sr.d_year,
    COUNT(DISTINCT ws.ws_order_number) AS distinct_web_orders,
    SUM(sr.sr_net_loss) AS total_store_return_loss,
    SUM(cs.cs_net_profit) AS total_catalog_sales_profit,
    SUM(ws.ws_net_paid) AS total_web_sales,
    AVG(i_sr.i_current_price) AS avg_item_price,
    MAX(p.p_discount_active) FILTER (WHERE p.p_discount_active IS NOT NULL) AS any_discount_active
FROM store_returns sr
JOIN date_dim d_sr
    ON sr.sr_returned_date_sk = d_sr.d_date_sk
JOIN store s
    ON sr.sr_store_sk = s.s_store_sk
JOIN household_demographics hd_sr
    ON sr.sr_hdemo_sk = hd_sr.hd_demo_sk
JOIN item i_sr
    ON sr.sr_item_sk = i_sr.i_item_sk
JOIN catalog_sales cs
    ON cs.cs_item_sk = i_sr.i_item_sk
JOIN date_dim d_cs
    ON cs.cs_sold_date_sk = d_cs.d_date_sk
JOIN call_center cc
    ON cs.cs_call_center_sk = cc.cc_call_center_sk
JOIN catalog_page cp
    ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN ship_mode sm
    ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN promotion p
    ON cs.cs_promo_sk = p.p_promo_sk
JOIN web_sales ws
    ON ws.ws_item_sk = i_sr.i_item_sk
JOIN household_demographics hd_ws
    ON ws.ws_bill_hdemo_sk = hd_ws.hd_demo_sk
JOIN web_page wp
    ON ws.ws_web_page_sk = wp.wp_web_page_sk
JOIN web_site wsite
    ON ws.ws_web_site_sk = wsite.web_site_sk
WHERE NOT EXISTS (
        SELECT 1
        FROM catalog_returns cr
        WHERE cr.cr_item_sk = sr.sr_item_sk
          AND cr.cr_returned_date_sk = sr.sr_returned_date_sk
    )
  AND i_sr.i_current_price > (SELECT mx_price FROM max_price)
GROUP BY
    s.s_store_id,
    d_sr.d_year
ORDER BY total_store_return_loss DESC
LIMIT 100
