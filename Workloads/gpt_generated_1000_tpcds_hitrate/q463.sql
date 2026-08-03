WITH filtered_sales AS (
    SELECT
        ws.ws_order_number,
        ws.ws_net_profit,
        ws.ws_sold_date_sk,
        ws.ws_promo_sk,
        ws.ws_bill_addr_sk,
        wp.wp_url,
        p.p_promo_name,
        concat(ca.ca_city, ', ', ca.ca_state) AS city_state,
        substring(p.p_promo_name, 1, 5) AS promo_prefix
    FROM web_sales ws
    JOIN promotion p
        ON ws.ws_promo_sk = p.p_promo_sk
    JOIN web_page wp
        ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN customer_address ca
        ON ws.ws_bill_addr_sk = ca.ca_address_sk
    WHERE regexp_like(p.p_channel_radio, '^N$')
      AND regexp_like(wp.wp_url, 'catalog')
      AND wp.wp_url LIKE '%example.com%'
),
returned_orders AS (
    SELECT wr.wr_order_number
    FROM web_returns wr
),
valid_orders AS (
    SELECT ws_order_number
    FROM filtered_sales
    EXCEPT
    SELECT wr_order_number
    FROM returned_orders
),
net_sales AS (
    SELECT
        fs.ws_order_number,
        fs.ws_net_profit,
        fs.promo_prefix,
        fs.city_state
    FROM filtered_sales fs
    JOIN valid_orders vo
        ON fs.ws_order_number = vo.ws_order_number
)
SELECT
    ns.promo_prefix,
    COUNT(*) AS order_count,
    SUM(ns.ws_net_profit) AS total_net_profit,
    AVG(ns.ws_net_profit) AS avg_net_profit,
    (SELECT AVG(ws2.ws_net_profit) FROM web_sales ws2) AS overall_avg_profit
FROM net_sales ns
GROUP BY ns.promo_prefix
HAVING SUM(ns.ws_net_profit) > 1000
ORDER BY total_net_profit DESC
OFFSET 10 ROWS
LIMIT 100
