WITH full_join AS (
    SELECT
        cr.cr_returned_date_sk,
        cr.cr_reason_sk,
        cr.cr_return_amount,
        cr.cr_return_quantity,
        cr.cr_order_number,
        cr.cr_fee,
        cr.cr_return_ship_cost,
        cr.cr_net_loss,
        d.d_date,
        d.d_year,
        d.d_fy_quarter_seq,
        d.d_weekend,
        d.d_day_name,
        r.r_reason_desc,
        r.r_reason_id
    FROM catalog_returns cr
    FULL OUTER JOIN date_dim d
        ON cr.cr_returned_date_sk = d.d_date_sk
    LEFT JOIN reason r
        ON cr.cr_reason_sk = r.r_reason_sk
)
SELECT
    rw.cr_returned_date_sk,
    rw.cr_reason_sk,
    rw.d_date,
    rw.d_year,
    rw.d_day_name,
    rw.r_reason_desc,
    regexp_extract(rw.r_reason_desc, '^\\s*([^\\s]+)', 1) AS reason_first_word,
    CASE
        WHEN rw.r_reason_desc IS NOT NULL AND regexp_like(rw.r_reason_desc, '(?i)damaged|missing')
            THEN 'DamagedOrMissing'
        ELSE 'Other'
    END AS reason_category,
    concat(rw.r_reason_id, '_', CAST(rw.d_year AS varchar)) AS reason_year_key,
    rw.cr_return_amount,
    rw.cr_return_quantity,
    rw.cr_fee,
    rw.cr_return_ship_cost,
    rw.cr_net_loss,
    sum(rw.cr_return_amount) OVER (PARTITION BY rw.d_year) AS sum_return_amount_by_year,
    row_number() OVER (PARTITION BY rw.d_year ORDER BY rw.cr_return_amount DESC) AS rn_year,
    (SELECT COUNT(*) FROM catalog_returns cr2 WHERE cr2.cr_reason_sk = rw.cr_reason_sk) AS count_returns_same_reason
FROM full_join rw
WHERE
    (rw.d_day_name LIKE 'S%' OR rw.d_day_name IS NULL)
    AND EXISTS (
        SELECT 1
        FROM catalog_returns cr3
        WHERE cr3.cr_returned_date_sk = rw.cr_returned_date_sk
          AND cr3.cr_return_amount > 200
    )
ORDER BY
    sum_return_amount_by_year DESC,
    rn_year
LIMIT 100
