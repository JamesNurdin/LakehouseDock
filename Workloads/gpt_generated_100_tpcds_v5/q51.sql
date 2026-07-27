WITH catalog_customer_sales AS (
    SELECT
        cs.cs_bill_customer_sk AS customer_sk,
        SUM(cs.cs_net_profit) AS catalog_net_profit,
        COUNT(*) AS catalog_order_cnt
    FROM catalog_sales cs
    JOIN customer c
        ON cs.cs_bill_customer_sk = c.c_customer_sk
    WHERE regexp_like(c.c_email_address, '\\.edu$')
      AND substring(c.c_first_name, 1, 1) = 'A'
    GROUP BY cs.cs_bill_customer_sk
),
customer_info AS (
    SELECT
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        SUBSTRING(c.c_email_address, 1, 10) AS email_prefix
    FROM customer c
)
SELECT
    ci.c_customer_sk,
    ci.full_name,
    ci.email_prefix,
    cc.catalog_net_profit,
    cc.catalog_order_cnt,
    SUM(ws.ws_net_profit) AS web_net_profit,
    (SELECT MAX(catalog_net_profit) FROM catalog_customer_sales) AS max_catalog_profit
FROM catalog_customer_sales cc
JOIN customer_info ci
    ON cc.customer_sk = ci.c_customer_sk
JOIN web_sales ws
    ON ws.ws_bill_customer_sk = ci.c_customer_sk
JOIN web_page wp
    ON ws.ws_web_page_sk = wp.wp_web_page_sk
WHERE wp.wp_url LIKE '%example.com%'
  AND regexp_like(wp.wp_url, '^https?://www\\.example\\.com')
  AND EXISTS (
        SELECT 1
        FROM web_sales ws2
        WHERE ws2.ws_bill_customer_sk = ci.c_customer_sk
          AND ws2.ws_quantity > 5
    )
GROUP BY
    ci.c_customer_sk,
    ci.full_name,
    ci.email_prefix,
    cc.catalog_net_profit,
    cc.catalog_order_cnt
HAVING SUM(ws.ws_net_profit) > 0
ORDER BY cc.catalog_net_profit DESC
LIMIT 100
