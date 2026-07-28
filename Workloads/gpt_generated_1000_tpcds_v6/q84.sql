WITH purchases AS (
    SELECT
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        c.c_email_address,
        regexp_extract(c.c_email_address, '@(.*)$', 1) AS email_domain,
        SUM(
            COALESCE(ss.ss_net_paid, 0) +
            COALESCE(ws.ws_net_paid, 0) +
            COALESCE(cs.cs_net_paid, 0)
        ) AS total_net_paid,
        (
            COUNT(DISTINCT CASE WHEN ss.ss_ticket_number IS NOT NULL THEN 'store' END) +
            COUNT(DISTINCT CASE WHEN ws.ws_order_number IS NOT NULL THEN 'web' END) +
            COUNT(DISTINCT CASE WHEN cs.cs_order_number IS NOT NULL THEN 'catalog' END)
        ) AS channel_count
    FROM customer c
    LEFT JOIN store_sales ss
        ON ss.ss_customer_sk = c.c_customer_sk
    LEFT JOIN web_sales ws
        ON ws.ws_bill_customer_sk = c.c_customer_sk
    LEFT JOIN catalog_sales cs
        ON cs.cs_bill_customer_sk = c.c_customer_sk
    WHERE regexp_like(c.c_first_name, '^[AEIOUaeiou]')
      AND regexp_like(c.c_email_address, '@.*\\.com$')
      AND c.c_last_review_date BETWEEN 2452300 AND 2452600
    GROUP BY
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        c.c_email_address,
        regexp_extract(c.c_email_address, '@(.*)$', 1)
)
SELECT
    p.c_customer_sk,
    p.full_name,
    p.email_domain,
    p.total_net_paid,
    p.channel_count,
    CASE WHEN p.total_net_paid > 10000 THEN 'VIP' ELSE 'Regular' END AS customer_segment
FROM purchases p
WHERE NOT EXISTS (
    SELECT 1
    FROM store_returns sr
    WHERE sr.sr_customer_sk = p.c_customer_sk
)
ORDER BY p.total_net_paid DESC
LIMIT 100
