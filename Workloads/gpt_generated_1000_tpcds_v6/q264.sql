WITH returns_by_store AS (
  SELECT
    sr.sr_store_sk,
    SUM(sr.sr_net_loss) AS total_net_loss,
    AVG(sr.sr_return_amt_inc_tax) AS avg_return_amt,
    COUNT(*) AS return_cnt,
    MAX(sr.sr_return_ship_cost) AS max_ship_cost
  FROM store_returns sr
  GROUP BY sr.sr_store_sk
)
SELECT
  s.s_market_manager,
  substr(s.s_zip, 1, 3) AS zip_prefix,
  r.total_net_loss,
  r.avg_return_amt,
  r.return_cnt,
  CASE
    WHEN regexp_extract(s.s_market_manager, '(\\w+) (\\w+)', 1) IS NOT NULL
    THEN regexp_extract(s.s_market_manager, '(\\w+) (\\w+)', 1)
    ELSE s.s_market_manager
  END AS manager_first_name,
  CONCAT(s.s_city, ', ', s.s_state) AS city_state
FROM store s
JOIN returns_by_store r
  ON s.s_store_sk = r.sr_store_sk
WHERE
  regexp_like(s.s_market_manager, '^D.*')
  AND s.s_zip LIKE '4%'
  AND EXISTS (
        SELECT 1
        FROM store_returns sr2
        WHERE sr2.sr_store_sk = s.s_store_sk
          AND sr2.sr_return_amt_inc_tax > 1000
      )
ORDER BY r.total_net_loss DESC
LIMIT 100
