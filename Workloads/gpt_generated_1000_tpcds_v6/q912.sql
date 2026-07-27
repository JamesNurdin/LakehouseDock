SELECT
    d.d_year,
    r.r_reason_desc,
    SUM(sr.sr_net_loss) AS total_net_loss,
    COUNT(*) AS return_cnt
FROM store_returns sr
JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
WHERE d.d_quarter_seq = 10
  AND sr.sr_return_tax > 5.00
GROUP BY d.d_year, r.r_reason_desc

UNION ALL

SELECT
    d.d_year,
    r.r_reason_desc,
    SUM(sr.sr_net_loss) AS total_net_loss,
    COUNT(*) AS return_cnt
FROM store_returns sr
JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
WHERE d.d_quarter_seq = 14
  AND sr.sr_return_ship_cost < 50.00
GROUP BY d.d_year, r.r_reason_desc

ORDER BY total_net_loss DESC
LIMIT 100
