WITH store_returns_full AS (
  SELECT
    s.s_store_id,
    d.d_date AS return_date,
    sr.sr_return_amt,
    agg.total_return_amt
  FROM store s
  FULL OUTER JOIN store_returns sr
    ON s.s_store_sk = sr.sr_store_sk
  LEFT JOIN date_dim d
    ON sr.sr_returned_date_sk = d.d_date_sk
  CROSS JOIN LATERAL (
    SELECT SUM(sr2.sr_return_amt) AS total_return_amt
    FROM store_returns sr2
    WHERE sr2.sr_store_sk = s.s_store_sk
  ) agg
)
SELECT *
FROM (
  SELECT
    srf.s_store_id AS store_id,
    srf.return_date,
    'Store' AS channel,
    srf.sr_return_amt AS return_amount,
    srf.total_return_amt,
    ROW_NUMBER() OVER (PARTITION BY 'Store' ORDER BY srf.sr_return_amt DESC NULLS LAST) AS rn
  FROM store_returns_full srf
  UNION ALL
  SELECT
    NULL AS store_id,
    d.d_date AS return_date,
    'Web' AS channel,
    wr.wr_return_amt AS return_amount,
    NULL AS total_return_amt,
    ROW_NUMBER() OVER (PARTITION BY 'Web' ORDER BY wr.wr_return_amt DESC NULLS LAST) AS rn
  FROM web_returns wr
  JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
  WHERE EXISTS (
    SELECT 1
    FROM web_sales ws
    WHERE ws.ws_order_number = wr.wr_order_number
      AND ws.ws_item_sk = wr.wr_item_sk
  )
) combined
ORDER BY combined.rn, combined.return_date DESC
LIMIT 100
