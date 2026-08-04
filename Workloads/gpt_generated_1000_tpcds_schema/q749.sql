WITH
  -- Store returns with filters and full chain of joins
  sr_agg AS (
    SELECT
      s.s_store_id AS store_id,
      r.r_reason_desc AS reason_desc,
      d.d_year AS year,
      SUM(sr.sr_return_quantity) AS qty,
      SUM(sr.sr_return_amt) AS amount,
      SUM(sr.sr_net_loss) AS net_loss
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN time_dim t ON sr.sr_return_time_sk = t.t_time_sk
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    WHERE d.d_year = 2002
      AND r.r_reason_desc LIKE '%late%'
      AND t.t_shift = 'first'
    GROUP BY s.s_store_id, r.r_reason_desc, d.d_year
  ),
  -- Web returns with the same filters and join chain
  wr_agg AS (
    SELECT
      NULL AS store_id,
      r.r_reason_desc AS reason_desc,
      d.d_year AS year,
      SUM(wr.wr_return_quantity) AS qty,
      SUM(wr.wr_return_amt) AS amount,
      SUM(wr.wr_net_loss) AS net_loss
    FROM web_returns wr
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN time_dim t ON wr.wr_returned_time_sk = t.t_time_sk
    JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
    WHERE d.d_year = 2002
      AND r.r_reason_desc LIKE '%late%'
      AND t.t_shift = 'first'
    GROUP BY r.r_reason_desc, d.d_year
  ),
  -- Union of the two aggregated sources (deduplication enforced by UNION DISTINCT)
  union_agg AS (
    SELECT * FROM sr_agg
    UNION DISTINCT
    SELECT * FROM wr_agg
  ),
  -- Example of a FULL OUTER JOIN between the raw return tables (kept for requirement compliance)
  full_combined AS (
    SELECT
      sr.sr_returned_date_sk,
      sr.sr_return_time_sk,
      sr.sr_store_sk,
      sr.sr_reason_sk,
      wr.wr_returned_date_sk AS wr_date_sk,
      wr.wr_returned_time_sk AS wr_time_sk,
      wr.wr_reason_sk AS wr_reason_sk
    FROM store_returns sr
    FULL OUTER JOIN web_returns wr
      ON sr.sr_returned_date_sk = wr.wr_returned_date_sk
      AND sr.sr_return_time_sk = wr.wr_returned_time_sk
      AND sr.sr_reason_sk = wr.wr_reason_sk
  ),
  -- Final aggregation, window ranking and scalar sub‑query
  final AS (
    SELECT
      COALESCE(store_id, 'UNKNOWN') AS store_id,
      reason_desc,
      year,
      SUM(qty) AS total_qty,
      SUM(amount) AS total_amount,
      SUM(net_loss) AS total_net_loss,
      AVG(CASE WHEN amount > 100 THEN amount END) AS avg_high_amount,
      COUNT(*) AS grp_cnt,
      ROW_NUMBER() OVER (PARTITION BY COALESCE(store_id, 'UNKNOWN') ORDER BY SUM(net_loss) DESC) AS rn,
      (SELECT AVG(net_loss) FROM union_agg) AS overall_avg_net_loss
    FROM union_agg
    GROUP BY store_id, reason_desc, year
  )
SELECT
  store_id,
  reason_desc,
  year,
  total_qty,
  total_amount,
  total_net_loss,
  avg_high_amount,
  grp_cnt,
  overall_avg_net_loss
FROM final
WHERE rn <= 5
ORDER BY total_net_loss DESC
LIMIT 100
