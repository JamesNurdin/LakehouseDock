WITH filtered_returns AS (
    SELECT
        wr.wr_returned_date_sk,
        wr.wr_returned_time_sk,
        wr.wr_item_sk,
        wr.wr_return_amt,
        wr.wr_return_tax,
        wr.wr_return_quantity
    FROM web_returns wr
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN item i ON wr.wr_item_sk = i.i_item_sk
    WHERE d.d_date BETWEEN DATE '2022-01-01' AND DATE '2022-12-31'
      AND regexp_like(i.i_item_desc, '[0-9]{3}')
      AND i.i_brand LIKE 'A%'
)
SELECT
    CONCAT(i.i_brand, '-', i.i_category) AS brand_category,
    d.d_month_seq AS month_seq,
    SUM(fr.wr_return_amt) AS total_return_amt,
    AVG(fr.wr_return_tax) AS avg_return_tax,
    COUNT(*) AS return_cnt,
    MAX(REGEXP_EXTRACT(i.i_item_desc, '([A-Z]{2}[0-9]{3})')) AS sample_code,
    MAX(SUBSTRING(i.i_item_desc, 1, 5)) AS sample_prefix
FROM filtered_returns fr
JOIN date_dim d ON fr.wr_returned_date_sk = d.d_date_sk
JOIN item i ON fr.wr_item_sk = i.i_item_sk
GROUP BY
    CONCAT(i.i_brand, '-', i.i_category),
    d.d_month_seq
HAVING SUM(fr.wr_return_amt) > 1000
ORDER BY total_return_amt DESC
LIMIT 100
