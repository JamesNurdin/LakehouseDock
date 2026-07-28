WITH filtered_customers AS (
    SELECT
        c.c_customer_sk,
        c.c_email_address,
        ca.ca_state,
        ca.ca_street_name,
        ca.ca_street_type,
        ca.ca_city,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name
    FROM customer c
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    WHERE regexp_like(c.c_email_address, '^.+@example\\.com$')
      AND regexp_like(ca.ca_street_name, '^(Jackson|Elm).*')
),
joined_data AS (
    SELECT
        fa.ca_state,
        wp.wp_type,
        fa.c_customer_sk,
        wp.wp_url,
        wr.wr_net_loss,
        wr.wr_return_tax
    FROM filtered_customers fa
    JOIN web_returns wr ON wr.wr_refunded_customer_sk = fa.c_customer_sk
    JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
    WHERE wp.wp_url LIKE '%/sale%'
      AND wp.wp_type LIKE 'C%'
)
SELECT
    ca_state,
    wp_type,
    COUNT(DISTINCT c_customer_sk) AS unique_customers,
    SUM(wr_net_loss) AS total_net_loss,
    AVG(wr_return_tax) AS avg_return_tax,
    REGEXP_EXTRACT(wp_url, 'https?://([^/]+)/', 1) AS domain
FROM joined_data
GROUP BY
    ca_state,
    wp_type,
    REGEXP_EXTRACT(wp_url, 'https?://([^/]+)/', 1)
ORDER BY total_net_loss DESC
LIMIT 100
