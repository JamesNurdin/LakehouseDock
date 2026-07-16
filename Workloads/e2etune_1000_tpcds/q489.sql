WITH agg AS (
    SELECT ib.ib_upper_bound,
           td.t_shift,
           COUNT(*) AS return_cnt,
           SUM(sr.sr_net_loss) AS total_net_loss,
           AVG(sr.sr_return_amt) AS avg_return_amount,
           SUM(sr.sr_refunded_cash) AS total_refunded_cash
    FROM store_returns sr
    JOIN household_demographics hd ON sr.sr_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN time_dim td ON sr.sr_return_time_sk = td.t_time_sk
    WHERE hd.hd_buy_potential IN ('1001-5000', '>10000')
      AND hd.hd_vehicle_count >= 1
      AND td.t_hour BETWEEN 9 AND 17
    GROUP BY ib.ib_upper_bound, td.t_shift
    HAVING COUNT(*) > 10
)
SELECT agg.ib_upper_bound,
       agg.t_shift,
       agg.return_cnt,
       agg.total_net_loss,
       agg.avg_return_amount,
       agg.total_refunded_cash,
       RANK() OVER (PARTITION BY agg.ib_upper_bound ORDER BY agg.total_net_loss DESC) AS net_loss_rank
FROM agg
ORDER BY agg.ib_upper_bound, agg.total_net_loss DESC
