WITH recent_returns AS (
    SELECT
        cr.cr_warehouse_sk,
        d.d_year,
        SUM(cr.cr_return_amount) AS total_return_amount,
        ROW_NUMBER() OVER (PARTITION BY cr.cr_warehouse_sk ORDER BY SUM(cr.cr_return_amount) DESC) AS rn
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
    WHERE d.d_year BETWEEN 2000 AND 2002
    GROUP BY cr.cr_warehouse_sk, d.d_year
)
SELECT
    'Return' AS activity_type,
    w.w_warehouse_name,
    d.d_year,
    SUM(cr.cr_return_amount) AS amount,
    rr.rn
FROM catalog_returns cr
JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
JOIN recent_returns rr ON rr.cr_warehouse_sk = cr.cr_warehouse_sk AND rr.d_year = d.d_year
WHERE w.w_state = 'NY'
GROUP BY w.w_warehouse_name, d.d_year, rr.rn

UNION ALL

SELECT
    'Sale' AS activity_type,
    w.w_warehouse_name,
    d.d_year,
    SUM(ws.ws_ext_sales_price) AS amount,
    NULL AS rn
FROM web_sales ws
JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
WHERE w.w_state = 'NY'
  AND NOT EXISTS (
        SELECT 1
        FROM catalog_returns cr2
        JOIN date_dim d2 ON cr2.cr_returned_date_sk = d2.d_date_sk
        JOIN warehouse w2 ON cr2.cr_warehouse_sk = w2.w_warehouse_sk
        WHERE w2.w_warehouse_sk = w.w_warehouse_sk
          AND d2.d_year = d.d_year
    )
GROUP BY w.w_warehouse_name, d.d_year

ORDER BY activity_type, amount DESC
LIMIT 100
