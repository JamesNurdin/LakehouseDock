WITH cat_sales AS (
    SELECT
        d.d_year,
        sm.sm_code,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        CASE WHEN SUM(cs.cs_ext_sales_price) > 100000 THEN 'High' ELSE 'Low' END AS sales_category,
        (SELECT COUNT(*) FROM catalog_page cp WHERE cp.cp_type = 'monthly') AS metric_cnt
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE d.d_year BETWEEN 2000 AND 2002
      AND sm.sm_code IN ('AIR', 'SEA')
    GROUP BY CUBE (d.d_year, sm.sm_code)
),
store_sales_agg AS (
    SELECT
        d.d_year,
        CAST(NULL AS varchar) AS sm_code,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        CASE WHEN SUM(ss.ss_ext_sales_price) > 100000 THEN 'High' ELSE 'Low' END AS sales_category,
        (SELECT COUNT(*) FROM store s WHERE s.s_state = 'CA') AS metric_cnt
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE d.d_year BETWEEN 2000 AND 2002
    GROUP BY CUBE (d.d_year)
),
union_all AS (
    SELECT * FROM cat_sales
    UNION ALL
    SELECT * FROM store_sales_agg
),
cross_dim AS (
    SELECT 'GroupA' AS grp UNION ALL SELECT 'GroupB' AS grp
)
SELECT
    u.d_year,
    u.sm_code,
    u.total_sales,
    u.sales_category,
    u.metric_cnt,
    cd.grp
FROM union_all u
CROSS JOIN cross_dim cd
WHERE NOT EXISTS (
    SELECT 1
    FROM web_site w
    WHERE w.web_state = 'CA'
      AND w.web_zip = u.sm_code
)
ORDER BY u.d_year DESC, u.total_sales DESC
LIMIT 100
