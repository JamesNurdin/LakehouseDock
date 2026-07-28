WITH sales_filtered AS (
    SELECT
        ws.ws_order_number,
        ws.ws_net_profit,
        ws.ws_sold_date_sk,
        ws.ws_ship_mode_sk,
        ws.ws_web_page_sk,
        ws.ws_web_site_sk,
        wp.wp_url,
        sm.sm_type,
        dd.d_year,
        dd.d_month_seq,
        wsite.web_site_id,
        regexp_extract(wp.wp_url, 'promo([0-9]+)', 1) AS promo_code,
        CASE
            WHEN sm.sm_type = 'AIR' THEN ws.ws_net_profit * 1.1
            WHEN sm.sm_type = 'GROUND' THEN ws.ws_net_profit * 0.95
            ELSE ws.ws_net_profit * 0.9
        END AS adjusted_profit
    FROM web_sales ws
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    JOIN web_site wsite ON ws.ws_web_site_sk = wsite.web_site_sk
    WHERE wp.wp_url LIKE '%promo%'
      AND regexp_like(wp.wp_url, 'promo[0-9]+')
)
SELECT
    web_site_id,
    d_year,
    d_month_seq,
    COALESCE(promo_code, 'N/A') AS promo_code,
    SUM(adjusted_profit) AS total_adjusted_profit,
    COUNT(*) AS num_transactions,
    CONCAT('Site_', web_site_id) AS site_label
FROM sales_filtered
GROUP BY web_site_id, d_year, d_month_seq, promo_code
ORDER BY total_adjusted_profit DESC
LIMIT 100
