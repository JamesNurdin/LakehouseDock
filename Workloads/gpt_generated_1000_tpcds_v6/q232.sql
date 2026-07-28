WITH high_pm AS (
  SELECT
    agg.store_sk,
    agg.period,
    agg.total_net_loss,
    agg.avg_fee_global,
    ROW_NUMBER() OVER (PARTITION BY agg.store_sk ORDER BY agg.total_net_loss DESC) AS loss_rank
  FROM (
    SELECT
      sr.sr_store_sk AS store_sk,
      t.t_am_pm AS period,
      SUM(sr.sr_net_loss) AS total_net_loss,
      (SELECT AVG(sr2.sr_fee) FROM store_returns sr2 WHERE sr2.sr_return_ship_cost > 200) AS avg_fee_global
    FROM store_returns sr
    JOIN time_dim t ON sr.sr_return_time_sk = t.t_time_sk
    WHERE sr.sr_return_ship_cost > 100
      AND t.t_am_pm = 'PM'
    GROUP BY sr.sr_store_sk, t.t_am_pm
  ) agg
),
low_am AS (
  SELECT
    agg.store_sk,
    agg.period,
    agg.total_net_loss,
    agg.avg_fee_global,
    ROW_NUMBER() OVER (PARTITION BY agg.store_sk ORDER BY agg.total_net_loss DESC) AS loss_rank
  FROM (
    SELECT
      sr.sr_store_sk AS store_sk,
      t.t_am_pm AS period,
      SUM(sr.sr_net_loss) AS total_net_loss,
      (SELECT AVG(sr2.sr_fee) FROM store_returns sr2 WHERE sr2.sr_return_ship_cost > 200) AS avg_fee_global
    FROM store_returns sr
    JOIN time_dim t ON sr.sr_return_time_sk = t.t_time_sk
    WHERE sr.sr_return_ship_cost <= 100
      AND t.t_am_pm = 'AM'
    GROUP BY sr.sr_store_sk, t.t_am_pm
  ) agg
)
SELECT store_sk,
       period,
       total_net_loss,
       avg_fee_global,
       loss_rank
FROM high_pm
WHERE loss_rank = 1
UNION ALL
SELECT store_sk,
       period,
       total_net_loss,
       avg_fee_global,
       loss_rank
FROM low_am
WHERE loss_rank = 1
ORDER BY total_net_loss DESC
LIMIT 100
