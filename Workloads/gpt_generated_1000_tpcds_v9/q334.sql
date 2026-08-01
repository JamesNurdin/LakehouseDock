WITH active_customers AS (
    SELECT customer_sk
    FROM (
        SELECT DISTINCT ws.ws_bill_customer_sk AS customer_sk
        FROM web_sales ws
        JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
        WHERE d.d_year = 2001
    )
    INTERSECT
    SELECT customer_sk
    FROM (
        SELECT DISTINCT ss.ss_customer_sk AS customer_sk
        FROM store_sales ss
        JOIN date_dim d2 ON ss.ss_sold_date_sk = d2.d_date_sk
        WHERE d2.d_year = 2001
    )
)
SELECT *
FROM (
    SELECT
        ws.ws_sold_date_sk AS date_sk,
        d.d_date AS sale_date,
        ws.ws_web_site_sk AS entity_sk,
        ws.ws_net_paid AS net_paid,
        ws.ws_net_profit AS net_profit,
        CASE WHEN ws.ws_net_paid > 1000 THEN 'High' ELSE 'Low' END AS sales_category,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_web_site_sk ORDER BY ws.ws_net_paid DESC) AS rn
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN web_site w ON ws.ws_web_site_sk = w.web_site_sk
    WHERE NOT EXISTS (
        SELECT 1
        FROM web_returns wr
        WHERE wr.wr_order_number = ws.ws_order_number
    )
      AND ws.ws_bill_customer_sk IN (SELECT customer_sk FROM active_customers)

    UNION ALL

    SELECT
        ss.ss_sold_date_sk AS date_sk,
        d2.d_date AS sale_date,
        ss.ss_store_sk AS entity_sk,
        ss.ss_net_paid AS net_paid,
        ss.ss_net_profit AS net_profit,
        CASE WHEN ss.ss_net_paid > 1000 THEN 'High' ELSE 'Low' END AS sales_category,
        ROW_NUMBER() OVER (PARTITION BY ss.ss_store_sk ORDER BY ss.ss_net_paid DESC) AS rn
    FROM store_sales ss
    JOIN date_dim d2 ON ss.ss_sold_date_sk = d2.d_date_sk
    WHERE ss.ss_customer_sk IN (SELECT customer_sk FROM active_customers)
) AS combined
ORDER BY sale_date DESC, net_paid DESC
LIMIT 100
