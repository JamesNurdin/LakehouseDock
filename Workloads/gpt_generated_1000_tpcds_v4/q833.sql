/* goal: Identify top-selling web pages for items whose description matches an alphanumeric pattern, limited to California customers and URLs containing 'sports', and produce a custom label */
WITH sales_filtered AS (
    SELECT
        ws.ws_web_page_sk,
        ws.ws_item_sk,
        ws.ws_net_paid,
        ws.ws_order_number,
        i.i_item_desc,
        wp.wp_type,
        wp.wp_url,
        ca.ca_state
    FROM tpcds.web_sales ws
    JOIN tpcds.item i
        ON ws.ws_item_sk = i.i_item_sk
    JOIN tpcds.web_page wp
        ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN tpcds.customer c
        ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN tpcds.customer_address ca
        ON c.c_current_addr_sk = ca.ca_address_sk
    WHERE regexp_like(i.i_item_desc, '[A-Za-z]{3}[0-9]{2}')
      AND wp.wp_url LIKE '%sports%'
      AND ca.ca_state = 'CA'
)
SELECT
    wp_type,
    ca_state,
    COUNT(DISTINCT ws_order_number) AS order_cnt,
    SUM(ws_net_paid) AS total_net_paid,
    CONCAT(wp_type, '-', SUBSTRING(i_item_desc, 1, 10)) AS label
FROM sales_filtered
GROUP BY
    wp_type,
    ca_state,
    CONCAT(wp_type, '-', SUBSTRING(i_item_desc, 1, 10))
ORDER BY total_net_paid DESC
LIMIT 100
