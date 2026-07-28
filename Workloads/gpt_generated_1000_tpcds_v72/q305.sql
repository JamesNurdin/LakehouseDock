WITH sales_by_day AS (
    SELECT
        d.d_date AS sale_date,
        d.d_day_name,
        regexp_extract(d.d_day_name, '^(\\w{3})', 1) AS day_abbrev,
        SUM(ss.ss_net_paid_inc_tax) AS total_sales,
        COUNT(*) AS sales_cnt
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE regexp_like(d.d_day_name, '^(Mon|Tue|Wed)')
      AND d.d_current_month = 'Y'
    GROUP BY d.d_date, d.d_day_name
),
inventory_by_day AS (
    SELECT
        d.d_date AS inv_date,
        d.d_day_name,
        regexp_extract(d.d_day_name, '^(\\w{3})', 1) AS day_abbrev,
        SUM(i.inv_quantity_on_hand) AS total_quantity,
        COUNT(*) AS inv_cnt
    FROM inventory i
    JOIN date_dim d ON i.inv_date_sk = d.d_date_sk
    WHERE regexp_like(d.d_day_name, '^(Mon|Tue|Wed)')
      AND d.d_current_month = 'Y'
      AND d.d_holiday LIKE '%Holiday%'
    GROUP BY d.d_date, d.d_day_name
)
SELECT
    source_type,
    activity_date,
    day_name,
    day_abbrev,
    total_sales,
    total_quantity,
    ROW_NUMBER() OVER (PARTITION BY source_type ORDER BY metric DESC) AS rank_desc
FROM (
    SELECT
        'sales' AS source_type,
        s.sale_date AS activity_date,
        s.d_day_name AS day_name,
        s.day_abbrev,
        s.total_sales,
        NULL AS total_quantity,
        s.total_sales AS metric
    FROM sales_by_day s
    UNION ALL
    SELECT
        'inventory' AS source_type,
        i.inv_date AS activity_date,
        i.d_day_name AS day_name,
        i.day_abbrev,
        NULL AS total_sales,
        i.total_quantity,
        i.total_quantity AS metric
    FROM inventory_by_day i
) combined
ORDER BY source_type, rank_desc
LIMIT 100
