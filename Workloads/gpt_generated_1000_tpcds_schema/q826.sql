WITH date_keys_a AS (
    SELECT d_date_sk
    FROM date_dim
    WHERE d_year = 2000
      AND d_month_seq BETWEEN 1 AND 6
),
date_keys_b AS (
    SELECT d_date_sk
    FROM date_dim
    WHERE d_week_seq >= 10 AND d_week_seq <= 20
),
common_dates AS (
    SELECT d_date_sk
    FROM date_keys_a
    INTERSECT
    SELECT d_date_sk
    FROM date_keys_b
),
filtered_returns AS (
    SELECT *
    FROM store_returns
    TABLESAMPLE BERNOULLI (10)
    WHERE sr_return_amt_inc_tax > 1000
      AND sr_reversed_charge < 50
)
SELECT
    ws.web_name,
    cp.cp_catalog_page_number,
    d.d_month_seq,
    SUM(fr.sr_return_amt_inc_tax) AS total_return_inc_tax,
    AVG(fr.sr_return_tax) AS avg_return_tax,
    COUNT(*) AS return_cnt,
    MIN(fr.sr_return_amt) AS min_return_amt,
    MAX(fr.sr_return_amt) AS max_return_amt,
    offset_val
FROM filtered_returns fr
JOIN common_dates cd ON fr.sr_returned_date_sk = cd.d_date_sk
JOIN date_dim d ON fr.sr_returned_date_sk = d.d_date_sk
JOIN catalog_page cp ON cp.cp_end_date_sk = d.d_date_sk
JOIN web_site ws ON ws.web_open_date_sk = d.d_date_sk
CROSS JOIN UNNEST(ARRAY[ws.web_gmt_offset, ws.web_tax_percentage]) AS t(offset_val)
WHERE cp.cp_department = 'Electronics'
  AND ws.web_country = 'US'
  AND ws.web_gmt_offset BETWEEN -5 AND 0
  AND EXISTS (
      SELECT 1
      FROM catalog_page cp2
      WHERE cp2.cp_catalog_page_number = cp.cp_catalog_page_number
        AND cp2.cp_department = 'Books'
  )
GROUP BY
    ws.web_name,
    cp.cp_catalog_page_number,
    d.d_month_seq,
    offset_val
ORDER BY total_return_inc_tax DESC
LIMIT 100
