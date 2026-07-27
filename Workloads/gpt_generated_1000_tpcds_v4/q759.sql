WITH returns_filtered AS (
    SELECT
        sr.sr_returned_date_sk,
        sr.sr_item_sk,
        sr.sr_reason_sk,
        sr.sr_return_amt,
        sr.sr_store_sk
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
),
item_filtered AS (
    SELECT
        i.i_item_sk,
        i.i_category,
        i.i_product_name,
        i.i_item_desc
    FROM item i
    WHERE REGEXP_LIKE(i.i_product_name, '^.*[0-9]{3}.*$')
),
reason_filtered AS (
    SELECT
        r.r_reason_sk,
        r.r_reason_desc
    FROM reason r
    WHERE r.r_reason_desc LIKE 'Customer%'
)
SELECT
    i.i_category,
    COUNT(DISTINCT rf.sr_store_sk) AS distinct_store_count,
    SUM(rf.sr_return_amt) AS total_return_amount,
    REGEXP_EXTRACT(i.i_product_name, '(\\d{3})') AS extracted_code,
    SUBSTRING(i.i_product_name, 1, 10) AS product_name_prefix
FROM returns_filtered rf
JOIN item_filtered i ON rf.sr_item_sk = i.i_item_sk
JOIN reason_filtered r ON rf.sr_reason_sk = r.r_reason_sk
WHERE REGEXP_LIKE(i.i_item_desc, '.*(large|XL).*')
GROUP BY
    i.i_category,
    REGEXP_EXTRACT(i.i_product_name, '(\\d{3})'),
    SUBSTRING(i.i_product_name, 1, 10)
HAVING SUM(rf.sr_return_amt) > 1000
ORDER BY total_return_amount DESC
LIMIT 100
