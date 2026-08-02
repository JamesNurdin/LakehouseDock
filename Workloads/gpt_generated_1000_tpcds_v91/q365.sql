WITH daily_returns AS (
    SELECT
        d.d_date_sk,
        d.d_year,
        d.d_month_seq,
        d.d_day_name,
        SUM(sr.sr_return_amt) AS store_return_amt,
        SUM(sr.sr_return_tax) AS store_return_tax,
        SUM(sr.sr_net_loss) AS store_net_loss,
        COUNT(sr.sr_ticket_number) AS store_return_cnt,
        SUM(wr.wr_return_amt) AS web_return_amt,
        SUM(wr.wr_return_tax) AS web_return_tax,
        SUM(wr.wr_net_loss) AS web_net_loss,
        COUNT(wr.wr_order_number) AS web_return_cnt,
        CASE WHEN SUM(sr.sr_net_loss) + SUM(wr.wr_net_loss) > 1000 THEN 'High' ELSE 'Low' END AS loss_category
    FROM tpcds.date_dim d
    LEFT JOIN tpcds.store_returns sr ON sr.sr_returned_date_sk = d.d_date_sk
    LEFT JOIN tpcds.web_returns wr ON wr.wr_returned_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
      AND d.d_quarter_seq BETWEEN 10 AND 20
      AND d.d_day_name IN ('Wednesday', 'Friday')
      AND sr.sr_return_tax > 0
      AND wr.wr_return_quantity > 5
    GROUP BY d.d_date_sk, d.d_year, d.d_month_seq, d.d_day_name
)
SELECT
    dr.d_year,
    dr.d_month_seq,
    dr.d_day_name,
    SUM(dr.store_return_amt) AS total_store_return_amt,
    SUM(dr.web_return_amt) AS total_web_return_amt,
    SUM(dr.store_net_loss + dr.web_net_loss) AS total_net_loss,
    COUNT(*) AS days_count,
    CASE WHEN SUM(dr.store_net_loss + dr.web_net_loss) > 5000 THEN 'Very High' ELSE 'Moderate' END AS overall_loss_category,
    ROW_NUMBER() OVER (PARTITION BY dr.d_year ORDER BY SUM(dr.store_return_amt + dr.web_return_amt) DESC) AS rn
FROM daily_returns dr
GROUP BY GROUPING SETS (
    (dr.d_year, dr.d_month_seq, dr.d_day_name),
    (dr.d_year, dr.d_month_seq),
    (dr.d_year),
    ()
)
HAVING SUM(dr.store_return_amt) > 1000
   AND SUM(dr.web_return_amt) > 500
   AND COUNT(*) >= 1
   AND SUM(dr.store_net_loss + dr.web_net_loss) > 0
ORDER BY dr.d_year, dr.d_month_seq, dr.d_day_name
LIMIT 100
