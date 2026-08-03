WITH sales_filtered AS (
    SELECT
        cs.cs_order_number,
        cs.cs_net_profit,
        cs.cs_quantity,
        cs.cs_warehouse_sk,
        cs.cs_catalog_page_sk,
        d.d_year,
        d.d_quarter_name,
        cp.cp_department,
        cp.cp_description,
        cp.cp_catalog_page_id,
        w.w_warehouse_name,
        w.w_city
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    WHERE d.d_current_quarter = 'Y'
      AND regexp_like(cp.cp_description, '(?i)special')
      AND cs.cs_order_number NOT IN (
          SELECT cr_order_number
          FROM catalog_returns
          WHERE cr_return_quantity > 0
      )
)
SELECT
    w.w_warehouse_name,
    cp.cp_department,
    SUM(s.cs_quantity) AS total_quantity,
    SUM(s.cs_net_profit) AS total_net_profit,
    CASE WHEN SUM(s.cs_net_profit) > 10000 THEN 'High' ELSE 'Low' END AS profit_category,
    CONCAT('Dept:', cp.cp_department, '-WH:', w.w_warehouse_name) AS combined_key,
    MIN(REGEXP_EXTRACT(cp.cp_catalog_page_id, '(\\d+)$')) AS page_id_suffix
FROM sales_filtered s
JOIN catalog_page cp ON s.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN warehouse w ON s.cs_warehouse_sk = w.w_warehouse_sk
GROUP BY ROLLUP (w.w_warehouse_name, cp.cp_department)
ORDER BY w.w_warehouse_name NULLS FIRST,
         cp.cp_department NULLS FIRST,
         total_net_profit DESC
