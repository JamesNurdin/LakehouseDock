WITH agg_returns AS (
    SELECT
        sr_item_sk,
        sr_store_sk,
        SUM(sr_return_quantity) AS total_quantity,
        SUM(sr_return_amt) AS total_return_amt,
        COUNT(*) AS return_cnt
    FROM store_returns
    WHERE sr_return_quantity >= 1
      AND sr_return_amt > 0
      AND sr_return_tax >= 0
      AND sr_return_ship_cost <= 100
      AND sr_refunded_cash IS NOT NULL
    GROUP BY sr_item_sk, sr_store_sk
)
SELECT
    i.i_item_id,
    i.i_brand,
    i.i_category_id,
    s.s_store_name,
    s.s_market_id,
    a.total_quantity,
    a.total_return_amt,
    a.return_cnt,
    CASE
        WHEN a.total_return_amt > 2000 THEN 'HIGH'
        WHEN a.total_return_amt > 500 THEN 'MEDIUM'
        ELSE 'LOW'
    END AS return_level,
    ROUND(a.total_return_amt / NULLIF(a.total_quantity, 0), 2) AS avg_return_per_qty,
    (
        SELECT AVG(sr2.sr_return_amt)
        FROM store_returns sr2
        WHERE sr2.sr_item_sk = i.i_item_sk
    ) AS avg_item_return_amt,
    RANK() OVER (PARTITION BY s.s_market_id ORDER BY a.total_return_amt DESC) AS market_return_rank
FROM agg_returns a
JOIN item i
    ON a.sr_item_sk = i.i_item_sk
JOIN store s
    ON a.sr_store_sk = s.s_store_sk
WHERE i.i_category_id IN (2, 6, 7)
  AND i.i_brand LIKE 'edu %'
  AND s.s_market_id IN (1, 2, 8)
  AND s.s_tax_percentage > 0.05
  AND a.total_quantity >= 10
  AND EXISTS (
        SELECT 1
        FROM store_returns sr3
        WHERE sr3.sr_item_sk = i.i_item_sk
          AND sr3.sr_refunded_cash > 100
      )
ORDER BY s.s_market_id, market_return_rank
LIMIT 100
