WITH cc_returns AS (
    SELECT
        'CallCenter' AS source_type,
        cc.cc_call_center_id AS entity_id,
        cc.cc_name AS entity_name,
        SUM(cr.cr_return_amount) AS total_return_amount
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
    WHERE d.d_year = 2001
    GROUP BY cc.cc_call_center_id, cc.cc_name
),
cp_returns AS (
    SELECT
        'CatalogPage' AS source_type,
        cp.cp_catalog_page_id AS entity_id,
        cp.cp_description AS entity_name,
        SUM(cr.cr_return_amount) AS total_return_amount
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    WHERE d.d_year = 2001
    GROUP BY cp.cp_catalog_page_id, cp.cp_description
)
SELECT source_type,
       entity_id,
       entity_name,
       total_return_amount
FROM cc_returns
UNION ALL
SELECT source_type,
       entity_id,
       entity_name,
       total_return_amount
FROM cp_returns
ORDER BY total_return_amount DESC
LIMIT 100
