WITH joined_sales AS (
    SELECT
        ws.ws_web_site_sk,
        ws.ws_ship_mode_sk,
        ws.ws_web_page_sk,
        ws.ws_ext_sales_price,
        ws.ws_net_profit,
        ws.ws_coupon_amt,
        ws.ws_quantity,
        sm.sm_carrier,
        sm.sm_contract,
        wp.wp_url,
        wp.wp_char_count,
        site.web_name,
        site.web_manager
    FROM tpcds.web_sales ws
    JOIN tpcds.ship_mode sm
        ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN tpcds.web_page wp
        ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN tpcds.web_site site
        ON ws.ws_web_site_sk = site.web_site_sk
    WHERE ws.ws_coupon_amt > 100
      AND ws.ws_quantity >= 50
      AND sm.sm_carrier = 'UPS'
      AND wp.wp_char_count BETWEEN 200 AND 2000
)
SELECT
    js.ws_web_site_sk,
    js.web_name,
    js.sm_carrier,
    js.sm_contract,
    SUM(js.ws_ext_sales_price)        AS site_total_sales,
    SUM(js.ws_net_profit)             AS site_total_profit,
    COUNT(*)                          AS txn_count,
    RANK() OVER (ORDER BY SUM(js.ws_net_profit) DESC) AS profit_rank,
    CASE
        WHEN SUM(js.ws_ext_sales_price) > 200000 THEN 'HIGH'
        WHEN SUM(js.ws_ext_sales_price) > 100000 THEN 'MEDIUM'
        ELSE 'LOW'
    END AS sales_category
FROM joined_sales js
GROUP BY
    js.ws_web_site_sk,
    js.web_name,
    js.sm_carrier,
    js.sm_contract
ORDER BY profit_rank
LIMIT 100
