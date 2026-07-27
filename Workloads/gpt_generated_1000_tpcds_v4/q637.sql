WITH
    high_window AS (
        SELECT
            sm.sm_carrier AS carrier,
            cp.cp_department AS department,
            CASE
                WHEN cr.cr_return_amount > 300 THEN 'High'
                ELSE 'Low'
            END AS category,
            SUM(cr.cr_return_amount) AS total_return_amount,
            COUNT(*) AS return_cnt,
            (
                SELECT MAX(cr2.cr_return_amount)
                FROM catalog_returns cr2
                WHERE cr2.cr_ship_mode_sk = sm.sm_ship_mode_sk
            ) > 200 AS flag
        FROM catalog_returns cr
        JOIN catalog_page cp
            ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
        JOIN ship_mode sm
            ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
        WHERE cr.cr_returned_date_sk BETWEEN 2450990 AND 2451000
          AND cp.cp_catalog_number IN (12, 4)
        GROUP BY
            sm.sm_carrier,
            cp.cp_department,
            CASE
                WHEN cr.cr_return_amount > 300 THEN 'High'
                ELSE 'Low'
            END,
            sm.sm_ship_mode_sk
    ),
    fedex_subset AS (
        SELECT
            sm.sm_carrier AS carrier,
            cp.cp_department AS department,
            CASE
                WHEN cr.cr_return_quantity >= 5 THEN 'Bulk'
                ELSE 'Single'
            END AS category,
            SUM(cr.cr_return_amount) AS total_return_amount,
            COUNT(*) AS return_cnt,
            EXISTS (
                SELECT 1
                FROM catalog_returns cr3
                WHERE cr3.cr_ship_mode_sk = sm.sm_ship_mode_sk
                  AND cr3.cr_returned_time_sk > 30000
            ) AS flag
        FROM catalog_returns cr
        JOIN catalog_page cp
            ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
        JOIN ship_mode sm
            ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
        WHERE sm.sm_carrier = 'FEDEX'
          AND cp.cp_catalog_number = 4
        GROUP BY
            sm.sm_carrier,
            cp.cp_department,
            CASE
                WHEN cr.cr_return_quantity >= 5 THEN 'Bulk'
                ELSE 'Single'
            END,
            sm.sm_ship_mode_sk
    )
SELECT
    carrier,
    department,
    category,
    total_return_amount,
    return_cnt,
    flag
FROM high_window
UNION ALL
SELECT
    carrier,
    department,
    category,
    total_return_amount,
    return_cnt,
    flag
FROM fedex_subset
