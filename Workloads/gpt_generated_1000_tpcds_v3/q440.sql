WITH sales_by_customer AS (
    SELECT
        c.c_customer_id,
        concat(c.c_first_name, ' ', c.c_last_name) AS full_name,
        regexp_extract(wp.wp_url, '(https?://[^/]+)', 1) AS domain,
        sum(ws.ws_net_paid) AS total_net_paid
    FROM
        web_sales ws
        JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
        JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
        JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE
        d.d_year = 2001
        AND wp.wp_url LIKE '%shop%'
        AND regexp_like(wp.wp_url, '^https?://.*\\.com')
    GROUP BY
        c.c_customer_id,
        concat(c.c_first_name, ' ', c.c_last_name),
        regexp_extract(wp.wp_url, '(https?://[^/]+)', 1)
)
SELECT
    c_customer_id,
    full_name,
    domain,
    total_net_paid,
    rank() OVER (PARTITION BY domain ORDER BY total_net_paid DESC) AS domain_rank
FROM
    sales_by_customer
ORDER BY
    total_net_paid DESC
LIMIT 100
