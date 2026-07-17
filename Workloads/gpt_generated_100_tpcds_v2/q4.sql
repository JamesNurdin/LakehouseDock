SELECT
    d.d_year,
    d.d_month_seq,
    SUM(ws.ws_net_paid) AS total_net_paid,
    SUM(ws.ws_net_profit) AS total_net_profit,
    COUNT(*) AS sales_count
FROM tpcds.web_sales ws
JOIN tpcds.date_dim d
    ON ws.ws_sold_date_sk = d.d_date_sk
WHERE d.d_date >= DATE '2001-01-01'
  AND d.d_date < DATE '2001-02-01'
GROUP BY d.d_year, d.d_month_seq
ORDER BY d.d_year, d.d_month_seq
