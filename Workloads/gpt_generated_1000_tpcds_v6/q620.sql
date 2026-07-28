WITH avg_sales AS (
    SELECT 'store' AS channel,
           avg(ss.ss_net_paid) AS avg_paid
    FROM store_sales ss
    UNION ALL
    SELECT 'web' AS channel,
           avg(ws.ws_net_paid) AS avg_paid
    FROM web_sales ws
),
combined AS (
    SELECT c.c_customer_id AS customer_id,
           sum(ss.ss_net_paid) AS total_paid
    FROM store_sales ss
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    WHERE s.s_state = 'CA'
      AND ss.ss_net_paid > (SELECT avg_paid FROM avg_sales WHERE channel = 'store')
    GROUP BY c.c_customer_id

    UNION ALL

    SELECT c.c_customer_id AS customer_id,
           sum(ws.ws_net_paid) AS total_paid
    FROM web_sales ws
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    WHERE wp.wp_type = 'HOME'
      AND ws.ws_net_paid > (SELECT avg_paid FROM avg_sales WHERE channel = 'web')
    GROUP BY c.c_customer_id
)
SELECT comb.customer_id,
       sum(comb.total_paid) AS combined_total_paid
FROM combined comb
JOIN customer c ON c.c_customer_id = comb.customer_id
WHERE NOT EXISTS (
    SELECT 1
    FROM catalog_returns cr
    WHERE cr.cr_returning_customer_sk = c.c_customer_sk
)
GROUP BY comb.customer_id
ORDER BY combined_total_paid DESC
LIMIT 100
