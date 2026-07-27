WITH filtered_returns AS (
    SELECT
        cr.cr_returned_date_sk,
        cr.cr_return_amount,
        cr.cr_return_quantity,
        r.r_reason_desc,
        regexp_extract(r.r_reason_id, '(\\d+)', 1) AS reason_id_num,
        i.i_brand,
        i.i_category,
        substring(i.i_item_desc, 1, 30) AS item_desc_snippet,
        d.d_year,
        d.d_month_seq,
        ib.ib_lower_bound,
        ib.ib_upper_bound
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    JOIN household_demographics hd ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE regexp_like(r.r_reason_desc, '(?i)missing|color')
      AND i.i_item_desc LIKE '%steel%'
)
SELECT
    d_year,
    d_month_seq,
    ib_lower_bound,
    ib_upper_bound,
    sum(cr_return_amount) AS total_return_amount,
    count(*) AS return_count,
    avg(cr_return_quantity) AS avg_return_quantity,
    max(CAST(reason_id_num AS integer)) AS max_reason_id_num,
    concat(i_brand, ' ', i_category) AS brand_category,
    min(item_desc_snippet) AS sample_item_desc
FROM filtered_returns
GROUP BY
    d_year,
    d_month_seq,
    ib_lower_bound,
    ib_upper_bound,
    i_brand,
    i_category
ORDER BY total_return_amount DESC
LIMIT 100
