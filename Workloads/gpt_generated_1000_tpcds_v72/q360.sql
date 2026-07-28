WITH sales_data AS (
    SELECT
        s.s_store_name,
        w.web_name,
        c.c_customer_sk,
        ca.ca_city,
        ss.ss_net_paid AS store_net_paid,
        ws.ws_net_paid AS web_net_paid,
        ws.ws_order_number,
        CASE WHEN ws.ws_order_number IS NOT NULL THEN 'Web' ELSE 'Store' END AS sales_channel,
        ROW_NUMBER() OVER (PARTITION BY s.s_store_name ORDER BY ss.ss_net_paid DESC) AS rn_within_store
    FROM store_sales ss
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN web_sales ws ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN web_site w ON ws.ws_web_site_sk = w.web_site_sk
    WHERE s.s_state = 'CA'
      AND ca.ca_state = 'CA'
      AND w.web_street_name LIKE 'River%'
      AND s.s_rec_start_date >= DATE '1998-01-01'
)
SELECT
    s_store_name,
    web_name,
    COUNT(DISTINCT c_customer_sk) AS unique_customers,
    SUM(store_net_paid) AS total_store_sales,
    SUM(web_net_paid) AS total_web_sales,
    SUM(CASE WHEN sales_channel = 'Web' THEN web_net_paid ELSE store_net_paid END) AS total_combined_sales,
    MIN(rn_within_store) AS best_store_rank
FROM sales_data
WHERE NOT EXISTS (
        SELECT 1
        FROM web_sales ws2
        WHERE ws2.ws_bill_customer_sk = sales_data.c_customer_sk
          AND ws2.ws_order_number = sales_data.ws_order_number
    )
GROUP BY s_store_name, web_name
HAVING SUM(CASE WHEN sales_channel = 'Web' THEN web_net_paid ELSE store_net_paid END) > 1000
ORDER BY total_combined_sales DESC
LIMIT 100
