WITH sales_agg AS (
    SELECT
        cp.cp_department,
        w.w_warehouse_name,
        SUM(cs.cs_net_profit) AS sales_profit,
        COUNT(*) AS sales_cnt
    FROM catalog_sales cs
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN time_dim t ON cs.cs_sold_time_sk = t.t_time_sk
    WHERE cp.cp_type = 'monthly'
      AND t.t_hour BETWEEN 9 AND 17
    GROUP BY cp.cp_department, w.w_warehouse_name
),
returns_agg AS (
    SELECT
        cp.cp_department,
        w.w_warehouse_name,
        SUM(cr.cr_net_loss) AS returns_loss,
        COUNT(*) AS returns_cnt
    FROM catalog_returns cr
    JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN time_dim t ON cr.cr_returned_time_sk = t.t_time_sk
    WHERE cp.cp_type = 'monthly'
      AND t.t_hour BETWEEN 9 AND 17
    GROUP BY cp.cp_department, w.w_warehouse_name
)
SELECT
    s.cp_department,
    s.w_warehouse_name,
    s.sales_profit - COALESCE(r.returns_loss, 0) AS net_profit,
    s.sales_cnt,
    COALESCE(r.returns_cnt, 0) AS returns_cnt,
    RANK() OVER (PARTITION BY s.w_warehouse_name ORDER BY (s.sales_profit - COALESCE(r.returns_loss, 0)) DESC) AS dept_rank
FROM sales_agg s
LEFT JOIN returns_agg r
    ON s.cp_department = r.cp_department
   AND s.w_warehouse_name = r.w_warehouse_name
WHERE (s.sales_profit - COALESCE(r.returns_loss, 0)) > 0
ORDER BY s.w_warehouse_name, dept_rank
LIMIT 20
