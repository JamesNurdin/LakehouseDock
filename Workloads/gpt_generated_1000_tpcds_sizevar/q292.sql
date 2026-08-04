WITH sr_sample AS (
       SELECT *
       FROM store_returns
       TABLESAMPLE BERNOULLI (10) -- sample 10% of store returns
   ),
   wr_sample AS (
       SELECT *
       FROM web_returns
   ),
   agg AS (
       SELECT
           d.d_year,
           s.s_state,
           ws.web_mkt_class,
           COUNT(DISTINCT sr_sample.sr_ticket_number) AS distinct_tickets,
           SUM(CASE WHEN sr_sample.sr_return_amt > 100 THEN sr_sample.sr_return_amt ELSE 0 END) AS high_return_amt,
           SUM(wr_sample.wr_return_amt) AS total_web_return_amt
       FROM date_dim d
       JOIN store s
         ON s.s_closed_date_sk = d.d_date_sk
       JOIN sr_sample
         ON sr_sample.sr_store_sk = s.s_store_sk
        AND sr_sample.sr_returned_date_sk = d.d_date_sk
       JOIN wr_sample
         ON wr_sample.wr_returned_date_sk = d.d_date_sk
       JOIN web_site ws
         ON ws.web_open_date_sk = d.d_date_sk
       WHERE d.d_year BETWEEN 2000 AND 2002
         AND d.d_month_seq IN (1, 2, 3)
         AND s.s_state = 'TX'
         AND ws.web_mkt_class LIKE '%Continuous%'
         AND d.d_current_month = 'Y'
       GROUP BY GROUPING SETS (
           (d.d_year, s.s_state),
           (d.d_year, ws.web_mkt_class),
           (s.s_state, ws.web_mkt_class),
           ()
       )
   )
SELECT
    d_year,
    s_state,
    web_mkt_class,
    distinct_tickets,
    high_return_amt,
    total_web_return_amt,
    RANK() OVER (PARTITION BY d_year ORDER BY high_return_amt DESC) AS rank_by_high_return,
    ROW_NUMBER() OVER (PARTITION BY s_state ORDER BY distinct_tickets DESC) AS rn_state
FROM agg
ORDER BY d_year DESC, distinct_tickets DESC
LIMIT 100
