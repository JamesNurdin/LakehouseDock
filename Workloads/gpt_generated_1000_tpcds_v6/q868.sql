WITH sales_page AS (
    SELECT
        ws.ws_bill_addr_sk,
        ws.ws_ship_addr_sk,
        ws.ws_web_page_sk,
        ws.ws_quantity,
        ws.ws_list_price,
        ws.ws_net_paid,
        ws.ws_ext_sales_price,
        ws.ws_ext_discount_amt,
        ws.ws_net_profit
    FROM web_sales ws
    WHERE ws.ws_list_price > 50
      AND ws.ws_quantity >= 2
)
SELECT
    ca.ca_state,
    ca.ca_city,
    wp.wp_type,
    COUNT(DISTINCT sp.ws_bill_addr_sk) AS bill_addr_cnt,
    SUM(sp.ws_ext_sales_price) AS total_sales,
    AVG(sp.ws_net_profit) AS avg_profit,
    MIN(sp.ws_list_price) AS min_list_price,
    MAX(sp.ws_list_price) AS max_list_price,
    COALESCE(wp.wp_image_count, 0) AS image_count
FROM sales_page sp
JOIN customer_address ca
    ON sp.ws_bill_addr_sk = ca.ca_address_sk
LEFT JOIN web_page wp
    ON sp.ws_web_page_sk = wp.wp_web_page_sk
    AND wp.wp_image_count >= 5
    AND wp.wp_link_count BETWEEN 10 AND 20
    AND wp.wp_url = 'http://www.foo.com'
    AND wp.wp_rec_start_date >= DATE '2001-01-01'
WHERE
    ca.ca_country = 'United States'
    AND ca.ca_street_type = 'Boulevard'
GROUP BY
    ca.ca_state,
    ca.ca_city,
    wp.wp_type,
    wp.wp_image_count
HAVING
    SUM(sp.ws_ext_sales_price) > (
        SELECT AVG(ws_ext_sales_price)
        FROM web_sales
    )
ORDER BY total_sales DESC
LIMIT 100
