WITH sr_agg AS (
    SELECT
        sr_returned_date_sk,
        sr_item_sk,
        COUNT(*) AS return_cnt,
        SUM(sr_return_quantity) AS total_qty,
        SUM(sr_return_amt) AS total_amt,
        AVG(sr_return_amt) AS avg_amt,
        MIN(sr_return_amt) AS min_amt,
        MAX(sr_return_amt) AS max_amt
    FROM store_returns
    WHERE sr_reversed_charge > 100.00
      AND sr_store_credit < 500.00
      AND sr_customer_sk IN (7202530, 9317383)
    GROUP BY sr_returned_date_sk, sr_item_sk
)
SELECT
    d.d_date,
    d.d_year,
    i.i_item_id,
    i.i_product_name,
    i.i_class_id,
    i.i_class,
    agg.return_cnt,
    agg.total_qty,
    agg.total_amt,
    agg.avg_amt,
    agg.min_amt,
    agg.max_amt
FROM sr_agg AS agg
JOIN date_dim d ON agg.sr_returned_date_sk = d.d_date_sk
JOIN item i ON agg.sr_item_sk = i.i_item_sk
WHERE d.d_current_day = 'N'
  AND d.d_year = 2001
  AND i.i_class_id IN (9, 11, 13)
  AND i.i_item_desc LIKE '%systems%'
ORDER BY d.d_date DESC, agg.total_amt DESC
LIMIT 100
