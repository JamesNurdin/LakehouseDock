WITH filtered_returns AS (
    SELECT
        sr.sr_store_sk,
        sr.sr_return_amt,
        i.i_item_desc,
        d.d_year
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    WHERE d.d_year BETWEEN 2000 AND 2002
      AND i.i_item_desc LIKE '%SPORT%'
      AND regexp_like(i.i_item_desc, '[0-9]{3}')
)
SELECT
    s.s_store_name,
    fr.d_year,
    CASE WHEN fr.sr_return_amt > 100 THEN 'High' ELSE 'Low' END AS return_category,
    COUNT(*) AS return_count,
    SUM(fr.sr_return_amt) AS total_return_amount,
    CONCAT(s.s_store_name, ' - ', SUBSTRING(fr.i_item_desc, 1, 15)) AS store_item_label
FROM filtered_returns fr
JOIN store s ON fr.sr_store_sk = s.s_store_sk
WHERE NOT EXISTS (
    SELECT 1
    FROM store_returns sr2
    JOIN date_dim d2 ON sr2.sr_returned_date_sk = d2.d_date_sk
    WHERE sr2.sr_store_sk = s.s_store_sk
      AND d2.d_year = 2001
)
GROUP BY
    s.s_store_name,
    fr.d_year,
    CASE WHEN fr.sr_return_amt > 100 THEN 'High' ELSE 'Low' END,
    CONCAT(s.s_store_name, ' - ', SUBSTRING(fr.i_item_desc, 1, 15))
ORDER BY total_return_amount DESC
LIMIT 100
