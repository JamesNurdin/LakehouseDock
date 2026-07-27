WITH ss_agg AS (
    SELECT
        ss.ss_customer_sk AS ss_customer_sk,
        ss.ss_promo_sk AS ss_promo_sk,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        AVG(ss.ss_net_profit) AS avg_profit
    FROM store_sales ss
    JOIN time_dim td ON ss.ss_sold_time_sk = td.t_time_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    GROUP BY ss.ss_customer_sk, ss.ss_promo_sk
)
SELECT
    c1.c_customer_id,
    ca_curr.ca_city,
    p1.p_promo_name,
    ss_agg.total_sales,
    ss_agg.avg_profit,
    CASE
        WHEN EXISTS (
            SELECT 1
            FROM web_sales ws2
            WHERE ws2.ws_bill_customer_sk = c1.c_customer_sk
              AND ws2.ws_net_profit > 1000
        ) THEN 'High Profit Customer'
        ELSE 'Regular Customer'
    END AS profit_category,
    cc.cc_name AS call_center_name,
    wsite.web_name AS website_name,
    (
        SELECT COUNT(*)
        FROM web_sales ws_cnt
        WHERE ws_cnt.ws_bill_customer_sk = c1.c_customer_sk
    ) AS web_sales_count
FROM ss_agg
JOIN customer c1 ON ss_agg.ss_customer_sk = c1.c_customer_sk
JOIN customer_address ca_curr ON c1.c_current_addr_sk = ca_curr.ca_address_sk
JOIN promotion p1 ON ss_agg.ss_promo_sk = p1.p_promo_sk
JOIN catalog_returns cr ON cr.cr_returning_customer_sk = c1.c_customer_sk
JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
JOIN time_dim td2 ON cr.cr_returned_time_sk = td2.t_time_sk
JOIN web_sales ws ON ws.ws_bill_customer_sk = c1.c_customer_sk
JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
JOIN web_site wsite ON ws.ws_web_site_sk = wsite.web_site_sk
JOIN customer c_ship ON ws.ws_ship_customer_sk = c_ship.c_customer_sk
JOIN customer_address ca_ship ON ws.ws_ship_addr_sk = ca_ship.ca_address_sk
ORDER BY ss_agg.total_sales DESC
LIMIT 100
