SELECT
    s.s_store_id,
    s.s_city,
    td.t_am_pm,
    SUM(ss.ss_net_paid_inc_tax) AS total_net_paid,
    SUM(sr.sr_net_loss) AS total_store_return_loss,
    SUM(wr.wr_net_loss) AS total_web_return_loss,
    COUNT(DISTINCT ss.ss_ticket_number) AS distinct_sales_tickets,
    CASE WHEN SUM(ss.ss_net_profit) > 0 THEN 'PROFIT' ELSE 'LOSS' END AS profit_flag,
    (
        SELECT AVG(ss2.ss_net_paid_inc_tax)
        FROM store_sales ss2
        JOIN store s2 ON ss2.ss_store_sk = s2.s_store_sk
        WHERE s2.s_store_id = s.s_store_id
    ) AS avg_store_net_paid
FROM store_sales ss
JOIN store s
    ON ss.ss_store_sk = s.s_store_sk
JOIN time_dim td
    ON ss.ss_sold_time_sk = td.t_time_sk
JOIN store_returns sr
    ON sr.sr_item_sk = ss.ss_item_sk
    AND sr.sr_ticket_number = ss.ss_ticket_number
    AND sr.sr_store_sk = s.s_store_sk
    AND sr.sr_return_time_sk = td.t_time_sk
JOIN web_returns wr
    ON wr.wr_returned_time_sk = td.t_time_sk
WHERE s.s_state = 'CA'
  AND ss.ss_net_paid_inc_tax > 1000
  AND td.t_hour BETWEEN 8 AND 18
  AND EXISTS (
        SELECT 1
        FROM store_returns sr_ex
        WHERE sr_ex.sr_store_sk = s.s_store_sk
          AND sr_ex.sr_net_loss > 0
    )
GROUP BY CUBE (s.s_store_id, s.s_city, td.t_am_pm)
ORDER BY total_net_paid DESC
LIMIT 100
