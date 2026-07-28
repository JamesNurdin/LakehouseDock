WITH filtered_returns AS (
    SELECT
        cr.cr_returned_date_sk,
        cr.cr_return_quantity,
        cr.cr_return_amount,
        cr.cr_return_tax,
        cr.cr_net_loss,
        cr.cr_reason_sk,
        cr.cr_item_sk,
        cr.cr_call_center_sk,
        cr.cr_catalog_page_sk,
        i.i_manufact,
        i.i_manufact_id,
        i.i_item_id,
        i.i_brand,
        r.r_reason_desc,
        c.cc_name,
        cp.cp_type
    FROM catalog_returns cr
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    JOIN call_center c ON cr.cr_call_center_sk = c.cc_call_center_sk
    JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    WHERE regexp_like(i.i_manufact, '^.*able$')
      AND r.r_reason_desc LIKE '%size%'
      AND cp.cp_type LIKE 'Web%'
),
aggregated AS (
    SELECT
        i_manufact,
        i_brand,
        i_manufact_id,
        i_item_id,
        COUNT(*) AS return_cnt,
        SUM(cr_return_amount) AS total_return_amount,
        SUM(cr_return_quantity) AS total_quantity,
        CONCAT('Manu-', CAST(i_manufact_id AS varchar), '-', SUBSTRING(i_item_id, 1, 5)) AS manuf_code_snippet
    FROM filtered_returns
    GROUP BY i_manufact, i_brand, i_manufact_id, i_item_id
    HAVING SUM(cr_return_amount) > 1000
)
SELECT
    i_manufact,
    i_brand,
    return_cnt,
    total_return_amount,
    total_quantity,
    manuf_code_snippet
FROM aggregated
ORDER BY total_return_amount DESC
LIMIT 100
