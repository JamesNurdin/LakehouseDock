SELECT r.r_reason_desc, SUM(sr.sr_net_loss) AS total_net_loss FROM store_returns sr JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk WHERE sr.sr_returned_date_sk = 2451628 GROUP BY r.r_reason_desc
