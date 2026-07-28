WITH page_returns AS (
    SELECT
        cp.cp_catalog_page_sk,
        cp.cp_catalog_page_number,
        cp.cp_department,
        cp.cp_description,
        w.w_warehouse_name,
        d.d_year,
        SUM(cr.cr_return_amount) AS total_return_amount,
        COUNT(*) AS return_cnt,
        AVG(cr.cr_return_amount) AS avg_return_amount,
        SUM(CASE WHEN cr.cr_return_tax > 0 THEN cr.cr_return_tax ELSE 0 END) AS total_tax
    FROM catalog_returns cr
    JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    WHERE regexp_like(cp.cp_description, '(?i)season|sale')
      AND cp.cp_type LIKE 'C%'
    GROUP BY cp.cp_catalog_page_sk,
             cp.cp_catalog_page_number,
             cp.cp_department,
             cp.cp_description,
             w.w_warehouse_name,
             d.d_year
    HAVING SUM(cr.cr_return_amount) > 1000
)
SELECT
    pr.cp_catalog_page_number,
    pr.cp_department,
    pr.w_warehouse_name,
    pr.d_year,
    pr.total_return_amount,
    pr.return_cnt,
    pr.avg_return_amount,
    pr.total_tax,
    CASE 
        WHEN pr.total_return_amount > 5000 THEN 'High'
        WHEN pr.total_return_amount > 2000 THEN 'Medium'
        ELSE 'Low'
    END AS return_level,
    (SELECT AVG(cr2.cr_return_amount)
       FROM catalog_returns cr2) AS overall_avg_return,
    (SELECT SUM(pr2.total_return_amount)
       FROM page_returns pr2
       WHERE pr2.cp_department = pr.cp_department
         AND pr2.d_year = pr.d_year
         AND pr2.cp_catalog_page_sk <> pr.cp_catalog_page_sk) AS dept_year_total_excluding_current,
    CASE WHEN EXISTS (
        SELECT 1
        FROM catalog_returns cr3
        WHERE cr3.cr_catalog_page_sk = pr.cp_catalog_page_sk
          AND cr3.cr_return_tax > 100
    ) THEN 1 ELSE 0 END AS high_tax_flag
FROM page_returns pr
ORDER BY pr.total_return_amount DESC
LIMIT 100
