WITH filtered_returns AS (
   SELECT
       wr.wr_returned_date_sk,
       wr.wr_return_quantity,
       wr.wr_return_amt,
       wr.wr_net_loss,
       wr.wr_returning_cdemo_sk
   FROM web_returns wr
   WHERE wr.wr_return_quantity > 1
     AND wr.wr_return_amt > 100
     AND wr.wr_returning_cdemo_sk IN (1664039, 776056)
),
agg AS (
   SELECT
       cc.cc_name,
       cc.cc_mkt_id,
       d.d_year,
       SUM(fr.wr_net_loss) AS total_net_loss,
       AVG(fr.wr_return_amt) AS avg_return_amt,
       COUNT(*) AS return_cnt
   FROM filtered_returns fr
   JOIN date_dim d
     ON fr.wr_returned_date_sk = d.d_date_sk
   JOIN call_center cc
     ON cc.cc_closed_date_sk = d.d_date_sk
   WHERE cc.cc_state = 'CA'
     AND cc.cc_mkt_class = 'National'
     AND d.d_dow = 5
     AND d.d_year = 2002
   GROUP BY cc.cc_name, cc.cc_mkt_id, d.d_year
)
SELECT
    a.cc_name,
    a.cc_mkt_id,
    a.d_year,
    a.total_net_loss,
    a.avg_return_amt,
    a.return_cnt,
    ROW_NUMBER() OVER (PARTITION BY a.cc_mkt_id ORDER BY a.total_net_loss DESC) AS market_rank
FROM agg a
ORDER BY a.total_net_loss DESC
LIMIT 100
