WITH filtered_returns AS (
   SELECT
       wr.wr_returned_date_sk,
       wr.wr_refunded_hdemo_sk,
       wr.wr_returning_hdemo_sk,
       wr.wr_reason_sk,
       wr.wr_return_amt_inc_tax,
       wr.wr_return_tax,
       wr.wr_fee,
       wr.wr_net_loss,
       wr.wr_return_quantity
   FROM web_returns wr
   WHERE wr.wr_return_amt_inc_tax > 200
     AND wr.wr_return_quantity >= 1
     AND wr.wr_fee < 20
     AND wr.wr_return_tax BETWEEN 5 AND 50
     AND wr.wr_net_loss > 0
),
agg AS (
   SELECT
       d.d_year,
       d.d_month_seq,
       hd_refunded.hd_buy_potential,
       r.r_reason_desc,
       SUM(fr.wr_return_amt_inc_tax) AS total_return_inc_tax,
       AVG(fr.wr_return_tax) AS avg_return_tax,
       COUNT(*) AS return_count,
       MIN(fr.wr_return_quantity) AS min_quantity,
       MAX(fr.wr_return_quantity) AS max_quantity
   FROM filtered_returns fr
   JOIN date_dim d
     ON fr.wr_returned_date_sk = d.d_date_sk
    AND d.d_moy = 11
    AND d.d_current_year = 'Y'
   JOIN household_demographics hd_refunded
     ON fr.wr_refunded_hdemo_sk = hd_refunded.hd_demo_sk
    AND hd_refunded.hd_dep_count <= 2
   JOIN household_demographics hd_returning
     ON fr.wr_returning_hdemo_sk = hd_returning.hd_demo_sk
    AND hd_returning.hd_vehicle_count >= 1
   JOIN reason r
     ON fr.wr_reason_sk = r.r_reason_sk
    AND r.r_reason_desc LIKE '%damaged%'
   GROUP BY
       d.d_year,
       d.d_month_seq,
       hd_refunded.hd_buy_potential,
       r.r_reason_desc
)
SELECT
   a.d_year,
   a.d_month_seq,
   a.hd_buy_potential,
   a.r_reason_desc,
   a.total_return_inc_tax,
   a.avg_return_tax,
   a.return_count,
   a.min_quantity,
   a.max_quantity,
   SUM(a.total_return_inc_tax) OVER (PARTITION BY a.d_year) AS yearly_total_return_inc_tax,
   ROW_NUMBER() OVER (PARTITION BY a.d_year ORDER BY a.total_return_inc_tax DESC) AS rank_within_year
FROM agg a
ORDER BY a.total_return_inc_tax DESC
LIMIT 100
