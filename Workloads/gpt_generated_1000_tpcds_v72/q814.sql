WITH
    catalog_customer AS (
        SELECT DISTINCT cs.cs_bill_customer_sk AS customer_sk
        FROM catalog_sales cs
        JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
        WHERE regexp_like(cp.cp_catalog_page_id, '^AAAAAAA.*M.*$')
    ),
    web_customer AS (
        SELECT DISTINCT ws.ws_bill_customer_sk AS customer_sk
        FROM web_sales ws
        JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
        WHERE wp.wp_url LIKE '%promo%'
    ),
    combined_customers AS (
        SELECT customer_sk FROM catalog_customer
        UNION
        SELECT customer_sk FROM web_customer
    ),
    customer_info AS (
        SELECT
            c.c_customer_sk,
            c.c_customer_id,
            CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
            regexp_extract(c.c_email_address, '@(.+)$', 1) AS email_domain
        FROM customer c
    )
SELECT
    ci.c_customer_id,
    ci.full_name,
    ci.email_domain,
    SUM(COALESCE(cs.cs_net_profit, 0) + COALESCE(ws.ws_net_profit, 0)) AS total_net_profit,
    CASE
        WHEN SUM(COALESCE(cs.cs_net_profit, 0) + COALESCE(ws.ws_net_profit, 0)) > (
            SELECT AVG(profit) FROM (
                SELECT cs.cs_net_profit AS profit FROM catalog_sales cs
                UNION ALL
                SELECT ws.ws_net_profit FROM web_sales ws
            ) t
        ) THEN 'Above Avg'
        ELSE 'Below Avg'
    END AS profit_category
FROM combined_customers cc
JOIN customer_info ci ON cc.customer_sk = ci.c_customer_sk
LEFT JOIN catalog_sales cs ON cs.cs_bill_customer_sk = ci.c_customer_sk
LEFT JOIN web_sales ws ON ws.ws_bill_customer_sk = ci.c_customer_sk
GROUP BY
    ci.c_customer_id,
    ci.full_name,
    ci.email_domain
HAVING SUM(COALESCE(cs.cs_net_profit, 0) + COALESCE(ws.ws_net_profit, 0)) > 0
ORDER BY total_net_profit DESC
LIMIT 100
