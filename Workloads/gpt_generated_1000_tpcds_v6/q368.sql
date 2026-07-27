WITH recent_dates AS (
    SELECT d_date_sk, d_year, d_month_seq
    FROM date_dim
    WHERE d_year = 2002
),
warehouse_sales AS (
    SELECT
        w.w_warehouse_id AS location_id,
        w.w_city AS location_city,
        d.d_month_seq,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        SUM(cs.cs_net_profit) AS total_profit,
        'Warehouse' AS source_type
    FROM catalog_sales cs
    JOIN recent_dates d ON cs.cs_ship_date_sk = d.d_date_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    WHERE w.w_warehouse_sq_ft > 300000
    GROUP BY w.w_warehouse_id, w.w_city, d.d_month_seq
),
store_sales AS (
    SELECT
        s.s_store_id AS location_id,
        s.s_city AS location_city,
        d.d_month_seq,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        SUM(cs.cs_net_profit) AS total_profit,
        'Store' AS source_type
    FROM catalog_sales cs
    JOIN recent_dates d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN store s ON s.s_closed_date_sk = d.d_date_sk
    WHERE s.s_state = 'CA'
    GROUP BY s.s_store_id, s.s_city, d.d_month_seq
),
combined_sales AS (
    SELECT * FROM warehouse_sales
    UNION ALL
    SELECT * FROM store_sales
)
SELECT
    location_id,
    location_city,
    source_type,
    d_month_seq,
    total_sales,
    total_profit,
    CASE WHEN total_sales > 50000 THEN 'Large' ELSE 'Small' END AS size_category,
    ROW_NUMBER() OVER (PARTITION BY source_type ORDER BY total_sales DESC) AS sales_rank
FROM combined_sales
ORDER BY source_type, sales_rank
