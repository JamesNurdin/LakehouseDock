WITH filtered_returns AS (
    SELECT
        wr.wr_item_sk,
        wr.wr_reason_sk,
        wr.wr_return_amt,
        wr.wr_refunded_cash,
        wr.wr_return_quantity,
        wr.wr_returned_date_sk
    FROM web_returns wr
    WHERE wr.wr_refunded_cash > 100.00
      AND wr.wr_returned_date_sk BETWEEN 2450000 AND 2459999
      AND wr.wr_reason_sk IN (1, 5, 9)
)
SELECT
    i.i_brand,
    r.r_reason_desc,
    COUNT(*) AS return_count,
    SUM(fr.wr_return_amt) AS total_return_amount,
    AVG(fr.wr_refunded_cash) AS avg_refunded_cash,
    MAX(fr.wr_return_quantity) AS max_return_quantity,
    CASE
        WHEN SUM(fr.wr_return_amt) > 1000 THEN 'High'
        ELSE 'Low'
    END AS return_level
FROM filtered_returns fr
JOIN item i ON fr.wr_item_sk = i.i_item_sk
JOIN reason r ON fr.wr_reason_sk = r.r_reason_sk
WHERE i.i_container = 'Unknown'
  AND i.i_size = 'large'
  AND r.r_reason_desc LIKE '%working%'
GROUP BY i.i_brand, r.r_reason_desc
ORDER BY total_return_amount DESC
