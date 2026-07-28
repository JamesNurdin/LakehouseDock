WITH overall AS (
    SELECT AVG(sr_return_amt) AS overall_avg_return_amt
    FROM store_returns
)
SELECT
    i.i_category,
    i.i_manufact,
    COUNT(*) AS return_cnt,
    SUM(sr.sr_return_amt) AS total_return_amt,
    AVG(sr.sr_return_amt) AS avg_return_amt,
    MIN(sr.sr_return_amt) AS min_return_amt,
    MAX(sr.sr_return_amt) AS max_return_amt,
    overall.overall_avg_return_amt
FROM store_returns sr
JOIN item i
  ON sr.sr_item_sk = i.i_item_sk
CROSS JOIN overall
WHERE i.i_category = 'Women'
  AND i.i_manufact = 'barantipri'
  AND sr.sr_fee > 30
  AND sr.sr_reversed_charge < 500
  AND i.i_rec_start_date BETWEEN DATE '2000-01-01' AND DATE '2000-12-31'
GROUP BY i.i_category, i.i_manufact, overall.overall_avg_return_amt
ORDER BY total_return_amt DESC
LIMIT 100
