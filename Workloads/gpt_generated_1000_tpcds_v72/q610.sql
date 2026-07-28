WITH avg_wh AS (
    SELECT avg(w_warehouse_sq_ft) AS avg_sq_ft
    FROM warehouse
)
SELECT hour, metric_type, total_amount
FROM (
    SELECT
        td.t_hour AS hour,
        'sales' AS metric_type,
        sum(cs.cs_net_paid) AS total_amount
    FROM catalog_sales cs
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN time_dim td ON cs.cs_sold_time_sk = td.t_time_sk
    WHERE td.t_hour BETWEEN 9 AND 12
      AND w.w_city = 'North'
      AND w.w_warehouse_sq_ft > (SELECT avg_sq_ft FROM avg_wh)
      AND EXISTS (
          SELECT 1 FROM catalog_page cp2
          WHERE cp2.cp_catalog_page_sk = cs.cs_catalog_page_sk
            AND cp2.cp_department = 'Home'
      )
    GROUP BY td.t_hour
    UNION ALL
    SELECT
        td.t_hour AS hour,
        'returns' AS metric_type,
        sum(sr.sr_return_amt) AS total_amount
    FROM store_returns sr
    JOIN time_dim td ON sr.sr_return_time_sk = td.t_time_sk
    WHERE td.t_hour BETWEEN 9 AND 12
      AND sr.sr_return_amt > 100
    GROUP BY td.t_hour
) combined
ORDER BY hour, metric_type
