WITH returns_data AS (
    SELECT
        w.w_warehouse_name,
        r.r_reason_desc,
        SUM(cr.cr_return_amount) AS total_return_amount,
        COUNT(*) AS return_cnt,
        CASE WHEN SUM(cr.cr_return_amount) > 10000 THEN 'HIGH' ELSE 'LOW' END AS return_level,
        CASE WHEN SUM(cr.cr_return_amount) > (SELECT AVG(cr_return_amount) FROM catalog_returns) THEN 'ABOVE_AVG' ELSE 'BELOW_AVG' END AS avg_flag
    FROM catalog_returns cr
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN time_dim t ON cr.cr_returned_time_sk = t.t_time_sk
    WHERE t.t_hour BETWEEN 9 AND 17
      AND EXISTS (
          SELECT 1 FROM inventory i
          WHERE i.inv_warehouse_sk = w.w_warehouse_sk
            AND i.inv_quantity_on_hand > 500
      )
    GROUP BY w.w_warehouse_name, r.r_reason_desc
    HAVING COUNT(*) >= 5
),

sales_data AS (
    SELECT
        w.w_warehouse_name,
        'WEB_SALES' AS source,
        SUM(ws.ws_net_paid_inc_ship) AS total_sales_amount,
        COUNT(*) AS sales_cnt,
        CASE WHEN SUM(ws.ws_net_paid_inc_ship) > 20000 THEN 'HIGH' ELSE 'LOW' END AS sales_level,
        NULL AS avg_flag
    FROM web_sales ws
    JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN time_dim t ON ws.ws_sold_time_sk = t.t_time_sk
    WHERE t.t_hour BETWEEN 9 AND 17
      AND EXISTS (
          SELECT 1 FROM inventory i
          WHERE i.inv_warehouse_sk = w.w_warehouse_sk
            AND i.inv_quantity_on_hand > 500
      )
    GROUP BY w.w_warehouse_name
    HAVING COUNT(*) >= 10
)
SELECT DISTINCT
    combined.w_warehouse_name,
    combined.category,
    combined.metric_value,
    combined.metric_cnt,
    combined.level,
    combined.avg_flag,
    combined.data_type
FROM (
    SELECT
        w_warehouse_name,
        r_reason_desc AS category,
        total_return_amount AS metric_value,
        return_cnt AS metric_cnt,
        return_level AS level,
        avg_flag,
        'RETURN' AS data_type
    FROM returns_data
    UNION ALL
    SELECT
        w_warehouse_name,
        source AS category,
        total_sales_amount AS metric_value,
        sales_cnt AS metric_cnt,
        sales_level AS level,
        avg_flag,
        'SALES' AS data_type
    FROM sales_data
) combined
ORDER BY metric_value DESC
LIMIT 100
