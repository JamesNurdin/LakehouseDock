WITH page_domains AS (
    SELECT
        wp.wp_web_page_sk,
        regexp_extract(wp.wp_url, 'https?://([^/]+)/', 1) AS domain
    FROM
        web_page wp
    WHERE
        wp.wp_url LIKE '%shop%'
        AND regexp_like(wp.wp_url, '^https?://[a-z]+\\.example\\.com')
)
SELECT
    ca.ca_state AS state,
    pd.domain,
    COUNT(DISTINCT ws.ws_order_number) AS orders,
    SUM(ws.ws_net_paid) AS total_paid
FROM
    web_sales ws
    JOIN page_domains pd ON ws.ws_web_page_sk = pd.wp_web_page_sk
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON ws.ws_bill_addr_sk = ca.ca_address_sk
WHERE
    d.d_date BETWEEN DATE '2001-01-01' AND DATE '2001-12-31'
GROUP BY
    ca.ca_state,
    pd.domain
ORDER BY
    total_paid DESC
LIMIT 100
