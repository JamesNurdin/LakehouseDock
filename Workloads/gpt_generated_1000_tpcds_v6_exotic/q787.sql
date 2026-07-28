WITH
    store_sales_agg AS (
        SELECT
            s.s_store_name AS store_name,
            td.t_meal_time AS meal_time,
            SUM(ss.ss_net_paid) AS net_paid,
            SUM(ss.ss_quantity) AS total_qty,
            CASE WHEN SUM(ss.ss_net_paid) > 100000 THEN 'High' ELSE 'Medium' END AS sales_category
        FROM
            store_sales ss
            JOIN store s ON ss.ss_store_sk = s.s_store_sk
            JOIN time_dim td ON ss.ss_sold_time_sk = td.t_time_sk
            JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
        WHERE
            td.t_meal_time = 'lunch'
            AND p.p_channel_tv = 'N'
        GROUP BY
            s.s_store_name,
            td.t_meal_time
    ),
    catalog_sales_agg AS (
        SELECT
            cp.cp_description AS store_name,
            td.t_meal_time AS meal_time,
            SUM(cs.cs_ext_sales_price) AS net_paid,
            SUM(cs.cs_quantity) AS total_qty,
            CASE WHEN SUM(cs.cs_ext_sales_price) > 50000 THEN 'High' ELSE 'Medium' END AS sales_category
        FROM
            catalog_sales cs
            JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
            JOIN time_dim td ON cs.cs_sold_time_sk = td.t_time_sk
            JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
        WHERE
            td.t_meal_time = 'dinner'
            AND p.p_purpose = 'Unknown'
        GROUP BY
            cp.cp_description,
            td.t_meal_time
    )
SELECT
    store_name,
    meal_time,
    net_paid,
    total_qty,
    sales_category
FROM store_sales_agg
UNION ALL
SELECT
    store_name,
    meal_time,
    net_paid,
    total_qty,
    sales_category
FROM catalog_sales_agg
ORDER BY net_paid DESC
LIMIT 100
