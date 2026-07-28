WITH filtered_sales AS (
    SELECT
        ca.ca_city,
        ca.ca_state,
        wp.wp_url,
        ws.ws_net_profit
    FROM web_sales ws
    JOIN customer_address ca ON ws.ws_bill_addr_sk = ca.ca_address_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    WHERE d.d_year = 2000
      AND regexp_like(ca.ca_city, '(?i)field')
      AND wp.wp_type LIKE 'p%'
      AND i.i_category = 'Electronics'
),
agg AS (
    SELECT
        concat(ca_city, ', ', ca_state) AS city_state,
        regexp_extract(wp_url, '^https?://([^/]+)/', 1) AS domain,
        sum(ws_net_profit) AS total_profit
    FROM filtered_sales
    GROUP BY 1, 2
)
SELECT DISTINCT
    city_state,
    domain,
    total_profit,
    rank() OVER (ORDER BY total_profit DESC) AS profit_rank
FROM agg
ORDER BY total_profit DESC
LIMIT 100
