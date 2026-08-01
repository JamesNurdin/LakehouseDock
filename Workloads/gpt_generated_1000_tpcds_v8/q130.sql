WITH filtered_sales AS (
    SELECT cs.cs_sold_date_sk,
           cs.cs_warehouse_sk,
           cs.cs_catalog_page_sk,
           cs.cs_net_paid_inc_tax,
           cs.cs_quantity,
           cs.cs_ext_ship_cost,
           cs.cs_ext_discount_amt
    FROM catalog_sales cs
    WHERE cs.cs_net_paid_inc_tax > 1000
),
distinct_warehouses AS (
    SELECT DISTINCT w.w_warehouse_sk,
                    w.w_warehouse_name,
                    w.w_state,
                    w.w_country
    FROM warehouse w
    WHERE w.w_country = 'United States'
)
SELECT dw.w_state,
       d.d_month_seq,
       cp.cp_department,
       SUM(fs.cs_net_paid_inc_tax)        AS total_net_paid_inc_tax,
       AVG(fs.cs_quantity)                AS avg_quantity,
       COUNT(*)                           AS sales_count,
       MIN(fs.cs_ext_ship_cost)           AS min_ship_cost,
       MAX(fs.cs_ext_discount_amt)       AS max_discount_amt
FROM filtered_sales fs
JOIN date_dim d
     ON fs.cs_sold_date_sk = d.d_date_sk
JOIN catalog_page cp
     ON fs.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN distinct_warehouses dw
     ON fs.cs_warehouse_sk = dw.w_warehouse_sk
WHERE d.d_year = 2001
  AND d.d_weekend = 'N'
GROUP BY ROLLUP (dw.w_state, d.d_month_seq, cp.cp_department)
ORDER BY dw.w_state ASC,
         d.d_month_seq ASC,
         cp.cp_department ASC NULLS LAST
LIMIT 100
