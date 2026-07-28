WITH daily_agg AS (
  SELECT
    d.d_date_sk,
    d.d_year,
    d.d_week_seq,
    SUM(sr.sr_return_amt) AS total_return_amt,
    SUM(sr.sr_return_quantity) AS total_return_qty,
    COUNT(*) AS return_count
  FROM store_returns sr
  JOIN date_dim d
    ON sr.sr_returned_date_sk = d.d_date_sk
  WHERE sr.sr_return_tax > 1.00
    AND sr.sr_return_amt_inc_tax > 10.00
    AND d.d_current_week = 'N'
  GROUP BY d.d_date_sk, d.d_year, d.d_week_seq
),

inventory_agg AS (
  SELECT
    i.inv_date_sk,
    SUM(i.inv_quantity_on_hand) AS total_qty_on_hand,
    COUNT(DISTINCT i.inv_warehouse_sk) AS warehouse_cnt
  FROM inventory i
  JOIN date_dim d
    ON i.inv_date_sk = d.d_date_sk
  WHERE i.inv_quantity_on_hand > 0
    AND d.d_week_seq BETWEEN 5 AND 20
  GROUP BY i.inv_date_sk
),

joined AS (
  SELECT
    da.d_date_sk,
    da.d_year,
    da.d_week_seq,
    da.total_return_amt,
    da.total_return_qty,
    da.return_count,
    ia.total_qty_on_hand,
    ia.warehouse_cnt
  FROM daily_agg da
  JOIN inventory_agg ia
    ON da.d_date_sk = ia.inv_date_sk
)
SELECT
  j.d_year,
  j.d_week_seq,
  j.total_return_amt,
  j.total_qty_on_hand,
  j.return_count,
  j.warehouse_cnt,
  j.total_return_amt / NULLIF(j.total_qty_on_hand, 0) AS return_per_qty,
  (
    SELECT COUNT(*)
    FROM store_returns sr2
    WHERE sr2.sr_returned_date_sk = j.d_date_sk
      AND sr2.sr_store_credit > 20.00
  ) AS high_credit_return_cnt
FROM joined j
WHERE j.return_count > 10
  AND j.warehouse_cnt >= 2
  AND j.total_return_amt > 500.00
ORDER BY j.d_year DESC, j.d_week_seq ASC
LIMIT 100
