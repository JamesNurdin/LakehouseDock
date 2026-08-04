WITH
  store_ret AS (
    SELECT
      sr.sr_returned_date_sk AS return_date_key,
      sr.sr_return_amt       AS return_amount,
      r.r_reason_desc        AS reason_desc,
      s.s_store_name         AS location_name,
      lt.reason_total        AS reason_total
    FROM store_returns sr
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    CROSS JOIN LATERAL (
      SELECT COUNT(*) AS reason_total
      FROM store_returns sr2
      WHERE sr2.sr_reason_sk = sr.sr_reason_sk
    ) AS lt
    WHERE sr.sr_return_tax > 2.45
      AND s.s_city = 'Spring'
  ),
  web_ret AS (
    SELECT
      wr.wr_returned_date_sk AS return_date_key,
      wr.wr_return_amt       AS return_amount,
      r.r_reason_desc        AS reason_desc,
      'Web'                  AS location_name,
      lt.reason_total        AS reason_total
    FROM web_returns wr
    JOIN web_sales ws ON wr.wr_order_number = ws.ws_order_number
    JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
    CROSS JOIN LATERAL (
      SELECT COUNT(*) AS reason_total
      FROM web_returns wr2
      WHERE wr2.wr_reason_sk = wr.wr_reason_sk
    ) AS lt
    WHERE wr.wr_return_tax > 2.45
      AND ws.ws_wholesale_cost < 50.00
  )
SELECT DISTINCT
  combined.return_date_key,
  combined.return_amount,
  combined.reason_desc,
  combined.location_name,
  combined.reason_total,
  ROW_NUMBER() OVER (ORDER BY combined.return_amount DESC) AS rn
FROM (
  SELECT * FROM store_ret
  UNION ALL
  SELECT * FROM web_ret
) AS combined
ORDER BY rn
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY
