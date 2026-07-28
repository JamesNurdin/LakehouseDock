WITH filtered_sales AS (
    SELECT
        ws.ws_sold_date_sk,
        ws.ws_ext_sales_price,
        ws.ws_net_profit,
        ca.ca_state,
        ca.ca_city,
        wp.wp_url,
        wsit.web_mkt_class
    FROM web_sales ws
    JOIN customer_address ca ON ws.ws_bill_addr_sk = ca.ca_address_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN web_site wsit ON ws.ws_web_site_sk = wsit.web_site_sk
    WHERE regexp_like(wp.wp_url, '^https?://.*\\.com')
      AND ca.ca_city LIKE 'San %'
)
SELECT
    ca_state,
    web_mkt_class,
    concat(ca_city, ', ', ca_state) AS city_state,
    sum(ws_ext_sales_price) AS total_sales,
    sum(ws_net_profit) AS total_profit,
    CASE WHEN sum(ws_net_profit) > 1000 THEN 'High' ELSE 'Low' END AS profit_category
FROM filtered_sales f
JOIN date_dim d ON f.ws_sold_date_sk = d.d_date_sk
WHERE d.d_year = 2000
GROUP BY ca_state, web_mkt_class, ca_city, ca_state
HAVING sum(ws_ext_sales_price) > 10000
ORDER BY total_sales DESC
LIMIT 100
