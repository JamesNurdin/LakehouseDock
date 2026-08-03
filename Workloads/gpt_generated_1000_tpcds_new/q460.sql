WITH sampled_sales AS (
    SELECT *
    FROM web_sales
    TABLESAMPLE BERNOULLI (10)
)
SELECT
    ca.ca_state,
    ca.ca_city,
    wp.wp_type,
    CASE
        WHEN ws.ws_net_paid_inc_ship_tax > 5000 THEN 'High'
        ELSE 'Low'
    END AS revenue_category,
    COUNT(*) AS order_count,
    SUM(ws.ws_net_paid_inc_ship_tax) AS total_revenue,
    AVG(ws.ws_wholesale_cost) AS avg_wholesale_cost,
    MIN(ws.ws_net_paid_inc_ship_tax) AS min_revenue,
    MAX(ws.ws_net_paid_inc_ship_tax) AS max_revenue,
    COUNT(DISTINCT ca.ca_zip) AS distinct_zips,
    COUNT(DISTINCT wp.wp_url) AS distinct_urls
FROM web_page wp
FULL OUTER JOIN sampled_sales ws
    ON ws.ws_web_page_sk = wp.wp_web_page_sk
LEFT JOIN customer_address ca
    ON ws.ws_bill_addr_sk = ca.ca_address_sk
WHERE
    ca.ca_state = 'CA'
    AND ca.ca_street_type = 'Ave'
    AND ca.ca_gmt_offset = -6.00
    AND wp.wp_rec_start_date BETWEEN DATE '1999-09-04' AND DATE '2001-09-03'
    AND ws.ws_net_paid_inc_ship_tax > 1000
    AND ws.ws_wholesale_cost < 50
GROUP BY
    ca.ca_state,
    ca.ca_city,
    wp.wp_type,
    CASE
        WHEN ws.ws_net_paid_inc_ship_tax > 5000 THEN 'High'
        ELSE 'Low'
    END
ORDER BY total_revenue DESC
LIMIT 100
