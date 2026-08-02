/* goal: Identify the top 100 customers by total web sales profit on selected page types, filtering by page access date range and high coupon amounts, and exclude any customers who also purchased on an 'ad' page on the same sale date. */
WITH filtered_sales AS (
    SELECT
        ws.ws_bill_customer_sk,
        ws.ws_web_page_sk,
        ws.ws_sold_date_sk,
        ws.ws_net_profit,
        ws.ws_coupon_amt
    FROM tpcds.web_sales ws
    JOIN tpcds.customer c
        ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN tpcds.web_page wp
        ON ws.ws_web_page_sk = wp.wp_web_page_sk
    WHERE
        wp.wp_type IN ('order', 'welcome', 'dynamic')                     -- predicate 1
        AND wp.wp_access_date_sk BETWEEN 2452555 AND 2452639               -- predicate 2
        AND ws.ws_coupon_amt > 500.00                                     -- predicate 3
)
SELECT
    c.c_customer_id,
    c.c_email_address,
    wp.wp_url,
    SUM(fs.ws_net_profit) AS total_profit,
    COUNT(*) AS sales_count,
    RANK() OVER (ORDER BY SUM(fs.ws_net_profit) DESC) AS profit_rank
FROM filtered_sales fs
JOIN tpcds.customer c
    ON fs.ws_bill_customer_sk = c.c_customer_sk
JOIN tpcds.web_page wp
    ON fs.ws_web_page_sk = wp.wp_web_page_sk
WHERE NOT EXISTS (
    SELECT 1
    FROM tpcds.web_sales ws2
    JOIN tpcds.web_page wp2
        ON ws2.ws_web_page_sk = wp2.wp_web_page_sk
    WHERE ws2.ws_bill_customer_sk = c.c_customer_sk
      AND wp2.wp_type = 'ad'
      AND ws2.ws_sold_date_sk = fs.ws_sold_date_sk
)
GROUP BY
    c.c_customer_id,
    c.c_email_address,
    wp.wp_url
ORDER BY total_profit DESC
LIMIT 100
