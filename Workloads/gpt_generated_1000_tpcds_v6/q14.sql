WITH filtered_sales AS (
    SELECT
        ws.ws_order_number,
        ws.ws_item_sk,
        ws.ws_bill_customer_sk,
        ws.ws_bill_addr_sk,
        ws.ws_net_profit,
        i.i_category,
        c.c_email_address,
        ca.ca_state,
        wp.wp_url
    FROM web_sales ws
    JOIN item i
        ON ws.ws_item_sk = i.i_item_sk
    JOIN customer c
        ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN customer_address ca
        ON ws.ws_bill_addr_sk = ca.ca_address_sk
    JOIN web_page wp
        ON ws.ws_web_page_sk = wp.wp_web_page_sk
    WHERE
        regexp_like(c.c_email_address, '^[A-Za-z0-9._%+-]+@example\\.(com|org)$')
        AND wp.wp_url LIKE '%promo%'
),
aggregated AS (
    SELECT
        f.i_category,
        f.ca_state,
        COUNT(*) AS sales_cnt,
        SUM(f.ws_net_profit) AS total_profit,
        AVG(f.ws_net_profit) AS avg_profit,
        MAX(f.wp_url) AS sample_wp_url,
        MAX(f.c_email_address) AS sample_email
    FROM filtered_sales f
    GROUP BY f.i_category, f.ca_state
)
SELECT
    a.i_category,
    a.ca_state,
    a.sales_cnt,
    a.total_profit,
    a.avg_profit,
    regexp_extract(a.sample_wp_url, 'https?://([^/]+)/', 1) AS domain_extracted,
    substring(a.sample_email, position('@' IN a.sample_email) + 1) AS email_domain
FROM aggregated a
ORDER BY a.total_profit DESC
LIMIT 100
