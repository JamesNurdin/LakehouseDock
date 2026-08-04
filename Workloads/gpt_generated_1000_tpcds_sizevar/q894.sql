WITH sampled_returns AS (
        SELECT * FROM catalog_returns TABLESAMPLE BERNOULLI (10)
    ),
    return_agg AS (
        SELECT
            w.w_warehouse_name AS warehouse_name,
            'Return' AS metric_type,
            SUM(cr.cr_net_loss) AS total_amount,
            CASE WHEN SUM(cr.cr_net_loss) > 1000 THEN 'HIGH' ELSE 'LOW' END AS flag,
            (SELECT AVG(cr2.cr_return_amount)
               FROM catalog_returns cr2
               WHERE cr2.cr_warehouse_sk = w.w_warehouse_sk) AS avg_return_amount,
            rc.return_cnt
        FROM sampled_returns cr
        JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
        JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
        JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
        LEFT JOIN LATERAL (
            SELECT COUNT(*) AS return_cnt
            FROM catalog_returns cr3
            WHERE cr3.cr_warehouse_sk = w.w_warehouse_sk
        ) rc ON TRUE
        WHERE d.d_year = 2001
          AND EXISTS (
                SELECT 1
                FROM reason r2
                WHERE r2.r_reason_sk = cr.cr_reason_sk
                  AND r2.r_reason_desc LIKE '%model%'
            )
        GROUP BY w.w_warehouse_name, w.w_warehouse_sk, rc.return_cnt
    ),
    sales_agg AS (
        SELECT
            w.w_warehouse_name AS warehouse_name,
            'Sales' AS metric_type,
            SUM(ws.ws_net_profit) AS total_amount,
            CASE WHEN SUM(ws.ws_net_profit) > 5000 THEN 'HIGH' ELSE 'LOW' END AS flag,
            CAST(NULL AS decimal(7,2)) AS avg_return_amount,
            CAST(NULL AS bigint) AS return_cnt
        FROM web_sales ws
        JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
        JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
        JOIN web_site s ON ws.ws_web_site_sk = s.web_site_sk
        WHERE d.d_year = 2001
          AND s.web_mkt_id IN (1, 3)
        GROUP BY w.w_warehouse_name, w.w_warehouse_sk
    )
SELECT *
FROM return_agg
UNION
SELECT *
FROM sales_agg
ORDER BY total_amount DESC
OFFSET 0
LIMIT 100
