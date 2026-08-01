WITH returns_by_store AS (
   SELECT
     s.s_store_sk,
     s.s_store_name,
     s.s_city,
     s.s_state,
     CONCAT(s.s_city, ', ', s.s_state) AS store_location,
     s.s_closed_date_sk,
     d.d_year,
     SUM(sr.sr_return_amt) AS total_return_amt,
     SUM(sr.sr_net_loss) AS total_net_loss,
     COUNT(*) AS num_returns,
     SUM(CASE WHEN REGEXP_LIKE(r.r_reason_desc, '^Damaged.*') THEN 1 ELSE 0 END) AS damaged_returns
   FROM store s
   JOIN store_returns sr ON s.s_store_sk = sr.sr_store_sk
   JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
   JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
   WHERE d.d_year = 2000
     AND s.s_state LIKE 'C%'
     AND REGEXP_LIKE(s.s_city, '^[A-Z][a-z]+$')
   GROUP BY s.s_store_sk, s.s_store_name, s.s_city, s.s_state, s.s_closed_date_sk, d.d_year
)
SELECT
  rbs.s_store_name,
  rbs.store_location,
  rbs.d_year,
  rbs.total_return_amt,
  rbs.total_net_loss,
  rbs.num_returns,
  rbs.damaged_returns,
  CASE
    WHEN rbs.total_net_loss > 10000 THEN 'HIGH_LOSS'
    WHEN rbs.total_net_loss > 5000 THEN 'MEDIUM_LOSS'
    ELSE 'LOW_LOSS'
  END AS loss_category
FROM returns_by_store rbs
WHERE NOT EXISTS (
  SELECT 1
  FROM date_dim d2
  JOIN call_center cc ON cc.cc_closed_date_sk = d2.d_date_sk
  WHERE d2.d_date_sk = rbs.s_closed_date_sk
)
ORDER BY rbs.total_net_loss DESC
LIMIT 100
