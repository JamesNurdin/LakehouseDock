WITH filtered AS (
    SELECT
        i.i_item_sk,
        i.i_brand,
        i.i_product_name,
        i.i_item_desc,
        i.i_rec_start_date,
        r.r_reason_desc,
        sr.sr_return_quantity,
        sr.sr_return_amt,
        sr.sr_return_ship_cost,
        regexp_extract(i.i_item_desc, '^([^ ]+)', 1) AS first_word,
        length(r.r_reason_desc) AS reason_len
    FROM store_returns sr
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    WHERE i.i_rec_start_date >= DATE '2000-01-01'
      AND i.i_rec_start_date < DATE '2001-01-01'
      AND regexp_like(i.i_item_desc, '(?i)(opportunity|manager)')
      AND r.r_reason_desc LIKE '%price%'
)
SELECT
    i_brand,
    first_word,
    i_rec_start_date,
    COUNT(*) AS return_count,
    SUM(sr_return_amt) AS total_return_amount,
    AVG(sr_return_quantity) AS avg_quantity,
    SUM(SUM(sr_return_amt)) OVER (PARTITION BY i_brand ORDER BY i_rec_start_date) AS cumulative_return_by_brand
FROM filtered
GROUP BY i_brand, first_word, i_rec_start_date
HAVING SUM(sr_return_amt) > 1000
ORDER BY cumulative_return_by_brand DESC
LIMIT 100
