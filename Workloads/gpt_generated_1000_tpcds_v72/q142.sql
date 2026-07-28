WITH filtered_sales AS (
    SELECT
        d.d_year,
        cp.cp_department,
        cs.cs_net_paid,
        cs.cs_net_profit,
        cr.cr_return_amount,
        regexp_extract(cp.cp_description, '(\\d{3})', 1) AS extracted_code
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    LEFT JOIN catalog_returns cr
        ON cr.cr_order_number = cs.cs_order_number
        AND cr.cr_item_sk = cs.cs_item_sk
    WHERE regexp_like(cp.cp_description, '\\d{3}')
      AND cp.cp_type LIKE 'A%'
),
agg AS (
    SELECT
        d_year,
        cp_department,
        SUM(cs_net_paid) AS total_net_paid,
        SUM(cs_net_profit) AS total_net_profit,
        SUM(COALESCE(cr_return_amount, 0)) AS total_return_amount,
        COUNT(*) AS sales_count,
        MAX(extracted_code) AS example_code
    FROM filtered_sales
    GROUP BY ROLLUP (d_year, cp_department)
)
SELECT
    d_year,
    cp_department,
    total_net_paid,
    total_net_profit,
    total_return_amount,
    sales_count,
    example_code,
    (
        SELECT AVG(cr2.cr_return_amount)
        FROM catalog_returns cr2
        JOIN catalog_sales cs2 ON cr2.cr_order_number = cs2.cs_order_number
                                AND cr2.cr_item_sk = cs2.cs_item_sk
        JOIN catalog_page cp2 ON cs2.cs_catalog_page_sk = cp2.cp_catalog_page_sk
        WHERE cp2.cp_department = agg.cp_department
    ) AS dept_avg_return_amount,
    SUM(total_net_profit) OVER (
        PARTITION BY cp_department
        ORDER BY d_year
        ROWS UNBOUNDED PRECEDING
    ) AS cumulative_profit_by_dept
FROM agg
ORDER BY d_year ASC NULLS LAST, cp_department
LIMIT 100
