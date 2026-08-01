WITH avg_catalog_profit AS (
    SELECT avg(cs2.cs_net_profit) AS avg_profit
    FROM catalog_sales cs2
),
top_customers AS (
    SELECT cs.cs_bill_customer_sk AS c_customer_sk
    FROM catalog_sales cs
    GROUP BY cs.cs_bill_customer_sk
    ORDER BY sum(cs.cs_net_profit) DESC
    LIMIT 10
)
SELECT
    cp.cp_department AS category,
    sum(cs.cs_net_profit) AS total_net_profit,
    'catalog' AS source_type
FROM catalog_sales cs
JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
WHERE cs.cs_net_profit > (SELECT avg_profit FROM avg_catalog_profit)
  AND c.c_customer_sk IN (SELECT c_customer_sk FROM top_customers)
  AND NOT EXISTS (
        SELECT 1
        FROM catalog_returns cr
        WHERE cr.cr_refunded_customer_sk = c.c_customer_sk
           OR cr.cr_returning_customer_sk = c.c_customer_sk
    )
GROUP BY cp.cp_department

UNION ALL

SELECT
    sm.sm_ship_mode_id AS category,
    sum(ws.ws_net_profit) AS total_net_profit,
    'web' AS source_type
FROM web_sales ws
JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
WHERE ws.ws_net_profit > (SELECT avg_profit FROM avg_catalog_profit)
  AND c.c_customer_sk IN (SELECT c_customer_sk FROM top_customers)
  AND NOT EXISTS (
        SELECT 1
        FROM catalog_returns cr
        WHERE cr.cr_refunded_customer_sk = c.c_customer_sk
           OR cr.cr_returning_customer_sk = c.c_customer_sk
    )
GROUP BY sm.sm_ship_mode_id

ORDER BY total_net_profit DESC
LIMIT 100
