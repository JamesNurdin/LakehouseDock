SELECT r.r_reason_desc, SUM(wr.wr_net_loss) AS total_net_loss FROM web_returns wr JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk WHERE wr.wr_returned_date_sk = 2451665 GROUP BY r.r_reason_desc
