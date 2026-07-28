WITH avg_catalog AS (
    SELECT avg(cs_net_paid) AS avg_net
    FROM catalog_sales
    WHERE cs_sold_date_sk IN (
        SELECT d_date_sk
        FROM date_dim
        WHERE d_year = 2001
    )
)
SELECT channel,
       customer_id,
       year,
       total_net_paid,
       distinct_orders
FROM (
    SELECT
        'Store' AS channel,
        c.c_customer_id AS customer_id,
        d.d_year AS year,
        SUM(ss.ss_net_paid) AS total_net_paid,
        COUNT(DISTINCT ss.ss_ticket_number) AS distinct_orders
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    WHERE d.d_year = 2001
      AND ss.ss_net_paid > (SELECT avg_net FROM avg_catalog)
      AND EXISTS (
          SELECT 1
          FROM catalog_returns cr
          WHERE cr.cr_refunded_customer_sk = c.c_customer_sk
      )
    GROUP BY c.c_customer_id, d.d_year
    HAVING SUM(ss.ss_net_paid) > 10000

    UNION ALL

    SELECT
        'Web' AS channel,
        c.c_customer_id AS customer_id,
        d.d_year AS year,
        SUM(ws.ws_net_paid) AS total_net_paid,
        COUNT(DISTINCT ws.ws_order_number) AS distinct_orders
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    WHERE d.d_year = 2001
      AND ws.ws_net_paid > (SELECT avg_net FROM avg_catalog)
      AND c.c_customer_sk IN (
          SELECT DISTINCT cr_refunded_customer_sk
          FROM catalog_returns
      )
    GROUP BY c.c_customer_id, d.d_year
    HAVING SUM(ws.ws_net_paid) > 10000
) AS combined
ORDER BY total_net_paid DESC
LIMIT 100
