/*
Goal: Compare daily net loss by shift for store and web returns in the year 2001, keeping only those day‑shift combinations where the total net loss exceeds $1,000. The result shows the date, shift, summed loss, summed return amount, number of returns and the source (store or web), ordered by most recent date and highest loss.
*/
SELECT
    d.d_date AS report_date,
    t.t_shift AS shift,
    SUM(sr.sr_net_loss) AS total_net_loss,
    SUM(sr.sr_return_amt) AS total_return_amount,
    COUNT(sr.sr_ticket_number) AS return_count,
    'store' AS source
FROM store_returns sr
JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
JOIN time_dim t ON sr.sr_return_time_sk = t.t_time_sk
JOIN household_demographics hd ON sr.sr_hdemo_sk = hd.hd_demo_sk
JOIN store s ON sr.sr_store_sk = s.s_store_sk
WHERE d.d_year = 2001
GROUP BY d.d_date, t.t_shift
HAVING SUM(sr.sr_net_loss) > 1000

UNION ALL

SELECT
    d.d_date AS report_date,
    t.t_shift AS shift,
    SUM(wr.wr_net_loss) AS total_net_loss,
    SUM(wr.wr_return_amt) AS total_return_amount,
    COUNT(wr.wr_order_number) AS return_count,
    'web' AS source
FROM web_returns wr
JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
JOIN time_dim t ON wr.wr_returned_time_sk = t.t_time_sk
JOIN household_demographics hd ON wr.wr_refunded_hdemo_sk = hd.hd_demo_sk
JOIN web_site ws ON ws.web_open_date_sk = d.d_date_sk
WHERE d.d_year = 2001
  AND ws.web_name = 'Main Site'
GROUP BY d.d_date, t.t_shift
HAVING SUM(wr.wr_net_loss) > 1000

ORDER BY report_date DESC, total_net_loss DESC
LIMIT 100
