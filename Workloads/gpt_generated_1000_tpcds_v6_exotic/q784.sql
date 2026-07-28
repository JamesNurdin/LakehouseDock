WITH store_sales_agg AS (
    SELECT
        d.d_date AS sales_date,
        s.s_store_name AS location_name,
        i.i_category AS category,
        SUM(ss.ss_ext_sales_price) AS total_sales
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    WHERE d.d_year = 2001
    GROUP BY d.d_date, s.s_store_name, i.i_category
),
catalog_sales_agg AS (
    SELECT
        d.d_date AS sales_date,
        w.w_warehouse_name AS location_name,
        i.i_category AS category,
        SUM(cs.cs_ext_sales_price) AS total_sales
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    WHERE d.d_year = 2001
      AND cp.cp_department = 'Books'
    GROUP BY d.d_date, w.w_warehouse_name, i.i_category
)
SELECT *
FROM (
    SELECT sales_date, location_name, category, total_sales FROM store_sales_agg
    UNION ALL
    SELECT sales_date, location_name, category, total_sales FROM catalog_sales_agg
) combined
ORDER BY sales_date ASC, total_sales DESC
LIMIT 100
