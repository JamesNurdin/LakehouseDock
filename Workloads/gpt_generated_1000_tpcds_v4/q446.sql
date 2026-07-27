WITH cat_ret AS (
    SELECT
        d.d_year AS year,
        d.d_month_seq AS month_seq,
        regexp_extract(r.r_reason_desc, '(\\w+)', 1) AS reason_word,
        SUM(cr.cr_return_amount) AS return_amount
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    WHERE regexp_like(r.r_reason_desc, '(?i)damage|defect')
      AND i.i_item_desc LIKE '%Bike%'
    GROUP BY d.d_year, d.d_month_seq, regexp_extract(r.r_reason_desc, '(\\w+)', 1)
),
web_ret AS (
    SELECT
        d.d_year AS year,
        d.d_month_seq AS month_seq,
        regexp_extract(r.r_reason_desc, '(\\w+)', 1) AS reason_word,
        SUM(wr.wr_return_amt) AS return_amount
    FROM web_returns wr
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
    JOIN item i ON wr.wr_item_sk = i.i_item_sk
    WHERE regexp_like(r.r_reason_desc, '(?i)damage|defect')
      AND i.i_item_desc LIKE '%Bike%'
    GROUP BY d.d_year, d.d_month_seq, regexp_extract(r.r_reason_desc, '(\\w+)', 1)
)
SELECT
    year,
    month_seq,
    reason_word,
    SUM(return_amount) AS total_return_amount
FROM (
    SELECT * FROM cat_ret
    UNION ALL
    SELECT * FROM web_ret
) AS combined
GROUP BY year, month_seq, reason_word
ORDER BY year, month_seq, total_return_amount DESC
