WITH store_agg AS (
    SELECT
        'store' AS sales_type,
        store.s_store_name AS entity_name,
        date_dim.d_year AS year,
        SUM(store_sales.ss_net_paid) AS total_sales,
        SUM(store_sales.ss_quantity) AS total_quantity
    FROM store_sales
    JOIN store ON store_sales.ss_store_sk = store.s_store_sk
    JOIN date_dim ON store_sales.ss_sold_date_sk = date_dim.d_date_sk
    WHERE date_dim.d_year = 2001
    GROUP BY store.s_store_name, date_dim.d_year
    HAVING SUM(store_sales.ss_net_paid) > 10000
),
catalog_agg AS (
    SELECT
        'call_center' AS sales_type,
        call_center.cc_name AS entity_name,
        date_dim.d_year AS year,
        SUM(catalog_sales.cs_net_paid_inc_ship) AS total_sales,
        SUM(catalog_sales.cs_quantity) AS total_quantity
    FROM catalog_sales
    JOIN call_center ON catalog_sales.cs_call_center_sk = call_center.cc_call_center_sk
    JOIN date_dim ON catalog_sales.cs_sold_date_sk = date_dim.d_date_sk
    WHERE date_dim.d_year = 2001
    GROUP BY call_center.cc_name, date_dim.d_year
    HAVING SUM(catalog_sales.cs_net_paid_inc_ship) > 10000
)
SELECT sales_type, entity_name, year, total_sales, total_quantity
FROM store_agg
UNION ALL
SELECT sales_type, entity_name, year, total_sales, total_quantity
FROM catalog_agg
ORDER BY total_sales DESC
LIMIT 100
