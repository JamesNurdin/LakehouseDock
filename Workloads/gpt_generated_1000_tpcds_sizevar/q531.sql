WITH filtered AS (
    SELECT
        cr.cr_return_amount,
        cr.cr_return_quantity,
        cc.cc_state,
        cc.cc_city,
        cp.cp_type,
        cp.cp_description,
        r.r_reason_desc,
        c.c_first_name,
        c.c_last_name,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS customer_full_name,
        SUBSTRING(cc.cc_city, 1, 3) AS city_prefix,
        CASE
            WHEN regexp_like(cp.cp_description, '^.*[0-9]{4}.*$') THEN 'Has4Digits'
            ELSE 'No4Digits'
        END AS description_tag
    FROM catalog_returns cr
    JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    JOIN customer c ON cr.cr_refunded_customer_sk = c.c_customer_sk
    WHERE cc.cc_state LIKE 'C%'
      AND regexp_like(cp.cp_type, '^promo.*')
      AND NOT EXISTS (
          SELECT 1
          FROM reason r2
          WHERE r2.r_reason_sk = cr.cr_reason_sk
            AND regexp_like(r2.r_reason_desc, '(?i)damaged')
      )
)
,
aggregated AS (
    SELECT
        state,
        reason_desc,
        description_tag,
        SUM(return_amount) AS total_return_amount,
        SUM(return_quantity) AS total_return_qty,
        COUNT(*) AS return_cnt
    FROM (
        SELECT
            cc_state AS state,
            r_reason_desc AS reason_desc,
            description_tag,
            cr_return_amount AS return_amount,
            cr_return_quantity AS return_quantity
        FROM filtered
    ) sub
    GROUP BY ROLLUP (state, reason_desc, description_tag)
)
SELECT
    ROW_NUMBER() OVER (ORDER BY state ASC NULLS LAST, reason_desc ASC NULLS LAST, description_tag ASC NULLS LAST) AS row_num,
    state,
    reason_desc,
    description_tag,
    total_return_amount,
    total_return_qty,
    return_cnt
FROM aggregated
ORDER BY state ASC NULLS LAST, reason_desc ASC NULLS LAST, description_tag ASC NULLS LAST
OFFSET 0 ROWS FETCH NEXT 20 ROWS ONLY
