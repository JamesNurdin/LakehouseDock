WITH sales_agg AS (
    SELECT
        c.c_customer_sk,
        c.c_email_address,
        SUM(ss.ss_net_profit) AS total_net_profit,
        COUNT(*) AS sales_cnt
    FROM store_sales ss
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    WHERE regexp_like(c.c_email_address, '^.+@.+\\.com$')
      AND c.c_email_address LIKE '%@example.com'
    GROUP BY c.c_customer_sk, c.c_email_address
),
customers_no_returns AS (
    SELECT c_customer_sk
    FROM sales_agg
    EXCEPT
    SELECT DISTINCT wr_refunded_customer_sk
    FROM web_returns
)
SELECT
    c.c_customer_sk,
    CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
    c.c_email_address,
    s.total_net_profit,
    CASE
        WHEN s.total_net_profit > 1000 THEN 'High'
        WHEN s.total_net_profit > 0 THEN 'Medium'
        ELSE 'Low'
    END AS profit_category,
    (
        SELECT COUNT(DISTINCT wp.wp_web_page_sk)
        FROM web_page wp
        WHERE wp.wp_customer_sk = c.c_customer_sk
          AND wp.wp_autogen_flag = 'N'
          AND regexp_extract(wp.wp_url, '(https?)://([^/]+)/', 2) = 'www.example.com'
    ) AS manual_page_count
FROM customers_no_returns cnr
JOIN customer c ON cnr.c_customer_sk = c.c_customer_sk
JOIN sales_agg s ON c.c_customer_sk = s.c_customer_sk
WHERE EXISTS (
    SELECT 1
    FROM web_page wp2
    WHERE wp2.wp_customer_sk = c.c_customer_sk
      AND wp2.wp_type LIKE 'product%'
)
ORDER BY s.total_net_profit DESC
LIMIT 100
