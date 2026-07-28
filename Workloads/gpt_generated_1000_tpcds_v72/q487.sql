WITH morning_returns AS (
    SELECT
        cc.cc_name,
        CASE WHEN cc.cc_tax_percentage > 0.05 THEN 'HighTax' ELSE 'LowTax' END AS tax_category,
        cp.cp_department,
        SUM(cr.cr_return_amount) AS total_return_amount,
        COUNT(*) AS return_cnt
    FROM catalog_returns cr
    JOIN time_dim td ON cr.cr_returned_time_sk = td.t_time_sk
    JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    WHERE td.t_am_pm = 'AM'
      AND cp.cp_department = 'Clothing'
    GROUP BY
        cc.cc_name,
        CASE WHEN cc.cc_tax_percentage > 0.05 THEN 'HighTax' ELSE 'LowTax' END,
        cp.cp_department
),

evening_returns AS (
    SELECT
        cc.cc_name,
        CASE WHEN cc.cc_tax_percentage > 0.05 THEN 'HighTax' ELSE 'LowTax' END AS tax_category,
        cp.cp_department,
        SUM(cr.cr_return_amount) AS total_return_amount,
        COUNT(*) AS return_cnt
    FROM catalog_returns cr
    JOIN time_dim td ON cr.cr_returned_time_sk = td.t_time_sk
    JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    WHERE td.t_am_pm = 'PM'
      AND cp.cp_department = 'Electronics'
    GROUP BY
        cc.cc_name,
        CASE WHEN cc.cc_tax_percentage > 0.05 THEN 'HighTax' ELSE 'LowTax' END,
        cp.cp_department
)
SELECT *
FROM morning_returns
UNION ALL
SELECT *
FROM evening_returns
ORDER BY total_return_amount DESC
LIMIT 100
