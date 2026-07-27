/*
Goal: Compare yearly total net paid sales from web channels with yearly total inventory quantity, and include the overall average coupon amount as a reference metric.
*/
WITH sales_per_year AS (
    SELECT
        d.d_year AS year,
        'sales' AS metric,
        SUM(ws.ws_net_paid) AS amount,
        (SELECT AVG(ws2.ws_coupon_amt) FROM tpcds.web_sales ws2) AS avg_coupon_amt
    FROM tpcds.web_sales ws
    JOIN tpcds.date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE ws.ws_web_site_sk IN (
        SELECT w.web_site_sk
        FROM tpcds.web_site w
        WHERE w.web_class = 'Unknown'
    )
    GROUP BY d.d_year
),
inventory_per_year AS (
    SELECT
        d.d_year AS year,
        'inventory' AS metric,
        SUM(i.inv_quantity_on_hand) AS amount,
        NULL AS avg_coupon_amt
    FROM tpcds.inventory i
    JOIN tpcds.date_dim d ON i.inv_date_sk = d.d_date_sk
    GROUP BY d.d_year
)
SELECT
    year,
    metric,
    amount,
    avg_coupon_amt
FROM sales_per_year
UNION ALL
SELECT
    year,
    metric,
    amount,
    avg_coupon_amt
FROM inventory_per_year
ORDER BY year, metric
LIMIT 100
