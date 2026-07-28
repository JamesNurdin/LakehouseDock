WITH combined AS (
    SELECT
        cp.cp_department AS department,
        dd.d_year,
        cs.cs_net_paid AS sales_amount,
        1 AS txn_cnt,
        CASE WHEN p.p_discount_active = 'Y' THEN 'Discount' ELSE 'No Discount' END AS discount_flag
    FROM catalog_sales cs
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN date_dim dd ON cs.cs_sold_date_sk = dd.d_date_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    WHERE dd.d_year = 2001

    UNION ALL

    SELECT
        'Store' AS department,
        dd.d_year,
        ss.ss_net_paid AS sales_amount,
        1 AS txn_cnt,
        CASE WHEN ss.ss_quantity > 10 THEN 'Bulk' ELSE 'Regular' END AS discount_flag
    FROM store_sales ss
    JOIN date_dim dd ON ss.ss_sold_date_sk = dd.d_date_sk
    WHERE dd.d_year = 2001
),
aggregated AS (
    SELECT
        department,
        d_year,
        SUM(sales_amount) AS total_sales,
        SUM(txn_cnt) AS txn_count,
        SUM(CASE WHEN discount_flag IN ('Discount', 'Bulk') THEN 1 ELSE 0 END) AS discount_txn_cnt
    FROM combined
    GROUP BY GROUPING SETS (
        (department, d_year),
        (department),
        (d_year),
        ()
    )
)
SELECT
    aggregated.department,
    aggregated.d_year,
    aggregated.total_sales,
    aggregated.txn_count,
    aggregated.discount_txn_cnt,
    RANK() OVER (PARTITION BY aggregated.department ORDER BY aggregated.total_sales DESC) AS dept_rank,
    (SELECT COUNT(*) FROM catalog_page cp2 WHERE cp2.cp_department = aggregated.department) AS dept_page_cnt
FROM aggregated
WHERE aggregated.department IS NOT NULL
ORDER BY aggregated.total_sales DESC NULLS LAST
LIMIT 100
