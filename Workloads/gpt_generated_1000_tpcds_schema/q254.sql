WITH grouped AS (
    SELECT
        we.web_name,
        we.web_site_sk,
        d.d_year,
        d.d_month_seq,
        SUM(ws.ws_net_paid) AS total_net_paid,
        COUNT(DISTINCT ws.ws_order_number) AS orders,
        COUNT(DISTINCT token) AS distinct_url_tokens,
        (
            SELECT avg(ws2.ws_net_paid)
            FROM web_sales ws2
            WHERE ws2.ws_web_site_sk = we.web_site_sk
        ) AS avg_site_net_paid
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN time_dim t ON ws.ws_sold_time_sk = t.t_time_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN web_site we ON ws.ws_web_site_sk = we.web_site_sk
    JOIN customer_address ca ON ws.ws_bill_addr_sk = ca.ca_address_sk
    CROSS JOIN UNNEST(split(wp.wp_url, '/')) AS u(token)
    WHERE d.d_year = 2000
      AND regexp_like(wp.wp_url, '^https?://.*\\.com')
      AND wp.wp_max_ad_count > 0
      AND ca.ca_city LIKE '%County'
    GROUP BY we.web_name, we.web_site_sk, d.d_year, d.d_month_seq
    HAVING SUM(ws.ws_net_paid) > 1000
)
SELECT
    g.web_name,
    g.d_year,
    g.d_month_seq,
    g.total_net_paid,
    g.orders,
    g.distinct_url_tokens,
    g.avg_site_net_paid,
    SUM(g.total_net_paid) OVER (
        PARTITION BY g.web_name
        ORDER BY g.d_year, g.d_month_seq
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS running_total_net_paid,
    LAG(g.total_net_paid) OVER (
        PARTITION BY g.web_name
        ORDER BY g.d_year, g.d_month_seq
    ) AS prior_month_net_paid
FROM grouped g
ORDER BY g.total_net_paid DESC
LIMIT 100
