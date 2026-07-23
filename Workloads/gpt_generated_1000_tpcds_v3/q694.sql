SELECT
    call_center_id,
    division_size,
    total_return_amount,
    max_return_amount
FROM (
    SELECT
        cc.cc_call_center_id AS call_center_id,
        CASE WHEN cc.cc_employees > 100 THEN 'Large' ELSE 'Small' END AS division_size,
        SUM(cr.cr_return_amount) AS total_return_amount,
        (SELECT MAX(cr2.cr_return_amount) FROM catalog_returns cr2) AS max_return_amount
    FROM catalog_returns cr
    JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN customer c ON cr.cr_refunded_customer_sk = c.c_customer_sk
    WHERE c.c_birth_country = 'VANUATU'
      AND cc.cc_division_name = 'cally'
      AND EXISTS (
            SELECT 1
            FROM catalog_page cp2
            WHERE cp2.cp_catalog_page_sk = cr.cr_catalog_page_sk
              AND cp2.cp_type = 'E'
        )
    GROUP BY
        cc.cc_call_center_id,
        CASE WHEN cc.cc_employees > 100 THEN 'Large' ELSE 'Small' END

    UNION ALL

    SELECT
        cc.cc_call_center_id AS call_center_id,
        CASE WHEN cc.cc_employees > 100 THEN 'Large' ELSE 'Small' END AS division_size,
        SUM(cr.cr_return_amount) AS total_return_amount,
        (SELECT MAX(cr2.cr_return_amount) FROM catalog_returns cr2) AS max_return_amount
    FROM catalog_returns cr
    JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN customer c ON cr.cr_returning_customer_sk = c.c_customer_sk
    WHERE c.c_birth_country = 'BARBADOS'
      AND cc.cc_division_name = 'able'
      AND EXISTS (
            SELECT 1
            FROM catalog_page cp2
            WHERE cp2.cp_catalog_page_sk = cr.cr_catalog_page_sk
              AND cp2.cp_type = 'C'
        )
    GROUP BY
        cc.cc_call_center_id,
        CASE WHEN cc.cc_employees > 100 THEN 'Large' ELSE 'Small' END
) AS combined
ORDER BY total_return_amount DESC
LIMIT 100
