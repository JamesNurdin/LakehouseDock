WITH filtered_returns AS (
    SELECT
        cr.cr_reason_sk,
        cr.cr_return_quantity,
        cr.cr_return_amount,
        cr.cr_net_loss,
        r.r_reason_desc,
        regexp_extract(r.r_reason_desc, '(?i)did not ([a-z]+)', 1) AS missing_action,
        CASE
            WHEN regexp_like(r.r_reason_desc, '(?i)damage') THEN 'Damage'
            WHEN regexp_like(r.r_reason_desc, '(?i)duplicate') THEN 'Duplicate'
            ELSE 'Other'
        END AS reason_category
    FROM catalog_returns cr
    JOIN reason r
        ON cr.cr_reason_sk = r.r_reason_sk
    WHERE r.r_reason_desc LIKE '%did not%'
      AND regexp_like(r.r_reason_id, '^A{8}B')
)
SELECT
    reason_category,
    missing_action,
    COUNT(*) AS returns_cnt,
    SUM(cr_return_quantity) AS total_qty,
    SUM(cr_return_amount) AS total_amount,
    SUM(cr_net_loss) AS total_net_loss,
    CONCAT('Category_', reason_category) AS category_label
FROM filtered_returns
GROUP BY reason_category, missing_action
ORDER BY total_net_loss DESC
LIMIT 100
