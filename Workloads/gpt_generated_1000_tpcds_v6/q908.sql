WITH start_pages AS (
    SELECT
        d.d_year AS year,
        cp.cp_department AS department,
        SUM(i.inv_quantity_on_hand) AS total_quantity,
        'START' AS period_type
    FROM catalog_page cp
    JOIN date_dim d ON cp.cp_start_date_sk = d.d_date_sk
    JOIN inventory i ON i.inv_date_sk = d.d_date_sk
    WHERE d.d_weekend = 'N'
      AND cp.cp_catalog_page_number BETWEEN 10 AND 20
    GROUP BY d.d_year, cp.cp_department
),
end_pages AS (
    SELECT
        d.d_year AS year,
        cp.cp_department AS department,
        SUM(i.inv_quantity_on_hand) AS total_quantity,
        'END' AS period_type
    FROM catalog_page cp
    JOIN date_dim d ON cp.cp_end_date_sk = d.d_date_sk
    JOIN inventory i ON i.inv_date_sk = d.d_date_sk
    WHERE d.d_weekend = 'Y'
      AND cp.cp_catalog_page_number BETWEEN 5 AND 15
    GROUP BY d.d_year, cp.cp_department
)
SELECT year, department, total_quantity, period_type
FROM start_pages
UNION ALL
SELECT year, department, total_quantity, period_type
FROM end_pages
ORDER BY year DESC, total_quantity DESC
LIMIT 100
