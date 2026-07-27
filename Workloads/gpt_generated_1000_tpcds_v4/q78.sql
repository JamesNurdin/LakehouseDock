WITH
  store_return_daily AS (
    SELECT
      d.d_date AS return_date,
      s.s_store_name AS store_name,
      SUM(sr.sr_return_amt) AS total_return_amt,
      COUNT(DISTINCT sr.sr_ticket_number) AS distinct_tickets,
      CASE WHEN SUM(sr.sr_return_amt) > 10000 THEN 'HIGH' ELSE 'NORMAL' END AS return_level
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    WHERE d.d_year = 2002
    GROUP BY d.d_date, s.s_store_name
    HAVING SUM(sr.sr_return_amt) > 0
  ),
  web_return_daily AS (
    SELECT
      d.d_date AS return_date,
      'WEB' AS store_name,
      SUM(wr.wr_return_amt) AS total_return_amt,
      COUNT(DISTINCT wr.wr_order_number) AS distinct_tickets,
      CASE WHEN SUM(wr.wr_return_amt) > 5000 THEN 'HIGH' ELSE 'NORMAL' END AS return_level
    FROM web_returns wr
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    WHERE d.d_year = 2002
    GROUP BY d.d_date
    HAVING SUM(wr.wr_return_amt) > 0
  ),
  combined_returns AS (
    SELECT
      return_date,
      store_name,
      total_return_amt,
      distinct_tickets,
      return_level
    FROM store_return_daily
    UNION ALL
    SELECT
      return_date,
      store_name,
      total_return_amt,
      distinct_tickets,
      return_level
    FROM web_return_daily
  )
SELECT DISTINCT
  cr.return_date,
  cr.store_name,
  cr.total_return_amt,
  cr.distinct_tickets,
  cr.return_level,
  (
    SELECT MAX(p.p_cost)
    FROM promotion p
    JOIN date_dim d2 ON (p.p_start_date_sk = d2.d_date_sk OR p.p_end_date_sk = d2.d_date_sk)
    WHERE d2.d_date = cr.return_date
  ) AS max_promo_cost
FROM combined_returns cr
JOIN date_dim d ON cr.return_date = d.d_date
WHERE EXISTS (
  SELECT 1
  FROM promotion p
  WHERE p.p_start_date_sk <= d.d_date_sk
    AND p.p_end_date_sk >= d.d_date_sk
)
ORDER BY cr.total_return_amt DESC
LIMIT 100
