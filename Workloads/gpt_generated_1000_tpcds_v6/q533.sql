WITH item_avg AS (
    SELECT
        i.i_item_sk,
        AVG(sr2.sr_return_amt) AS avg_return_amt
    FROM store_returns sr2
    JOIN item i ON sr2.sr_item_sk = i.i_item_sk
    WHERE sr2.sr_return_amt > 0
    GROUP BY i.i_item_sk
)
SELECT
    c.c_customer_id,
    i.i_brand,
    COUNT(*) AS num_returns,
    SUM(sr.sr_return_amt) AS total_return_amount,
    AVG(sr.sr_return_ship_cost) AS avg_ship_cost,
    ia.avg_return_amt
FROM store_returns sr
JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
JOIN item i ON sr.sr_item_sk = i.i_item_sk
JOIN item_avg ia ON i.i_item_sk = ia.i_item_sk
WHERE c.c_birth_month = 5
  AND sr.sr_reason_sk = 41
  AND i.i_wholesale_cost > 10.00
  AND EXISTS (
        SELECT 1
        FROM store_returns sr2
        WHERE sr2.sr_customer_sk = c.c_customer_sk
          AND sr2.sr_return_amt > 200
        LIMIT 1
      )
GROUP BY c.c_customer_id, i.i_brand, ia.avg_return_amt
ORDER BY total_return_amount DESC
LIMIT 100
