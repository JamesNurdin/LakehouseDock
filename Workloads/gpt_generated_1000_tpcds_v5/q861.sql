WITH sales_agg AS (
    SELECT
        cs.cs_catalog_page_sk,
        cs.cs_warehouse_sk,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        SUM(cs.cs_quantity) AS total_qty,
        AVG(cs.cs_list_price) AS avg_list_price,
        SUM(cs.cs_net_profit) AS total_profit,
        COUNT(*) AS order_cnt
    FROM catalog_sales cs
    JOIN catalog_page cp
        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN warehouse w
        ON cs.cs_warehouse_sk = w.w_warehouse_sk
    WHERE cs.cs_list_price BETWEEN 30 AND 200                     -- predicate 1
      AND cs.cs_quantity >= 2                                      -- predicate 2
      AND cp.cp_department = 'Home'                                -- predicate 3
      AND cp.cp_catalog_number IN (1, 7, 14)                       -- predicate 4
      AND w.w_gmt_offset = -6.00                                    -- predicate 5
      AND cp.cp_start_date_sk >= 2450900                           -- predicate 6
      AND cp.cp_end_date_sk <= 2451100                             -- predicate 7
    GROUP BY cs.cs_catalog_page_sk, cs.cs_warehouse_sk
)
SELECT
    sa.cs_catalog_page_sk,
    sa.cs_warehouse_sk,
    cp.cp_catalog_page_number,
    w.w_warehouse_name,
    sa.total_sales,
    sa.total_qty,
    sa.avg_list_price,
    sa.total_profit,
    CASE
        WHEN sa.total_profit > 10000 THEN 'HIGH'
        WHEN sa.total_profit > 0 THEN 'MEDIUM'
        ELSE 'LOW'
    END AS profit_category,
    RANK() OVER (ORDER BY sa.total_sales DESC) AS sales_rank,
    ROW_NUMBER() OVER (PARTITION BY sa.cs_warehouse_sk ORDER BY sa.total_profit DESC) AS profit_row_num
FROM sales_agg sa
JOIN catalog_page cp
    ON sa.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN warehouse w
    ON sa.cs_warehouse_sk = w.w_warehouse_sk
ORDER BY sales_rank
LIMIT 100
