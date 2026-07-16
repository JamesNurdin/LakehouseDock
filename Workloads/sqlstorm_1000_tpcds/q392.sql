WITH sales_summary AS (
    SELECT cs.cs_sold_date_sk AS date_sk,
           'catalog' AS channel,
           SUM(cs.cs_net_paid) AS total_paid,
           SUM(cs.cs_net_profit) AS total_profit
    FROM catalog_sales cs
    GROUP BY cs.cs_sold_date_sk
    UNION ALL
    SELECT ss.ss_sold_date_sk,
           'store',
           SUM(ss.ss_net_paid),
           SUM(ss.ss_net_profit)
    FROM store_sales ss
    GROUP BY ss.ss_sold_date_sk
    UNION ALL
    SELECT ws.ws_sold_date_sk,
           'web',
           SUM(ws.ws_net_paid),
           SUM(ws.ws_net_profit)
    FROM web_sales ws
    GROUP BY ws.ws_sold_date_sk
),
returns_summary AS (
    SELECT cr.cr_returned_date_sk AS date_sk,
           'catalog' AS channel,
           SUM(cr.cr_net_loss) AS total_returns
    FROM catalog_returns cr
    GROUP BY cr.cr_returned_date_sk
    UNION ALL
    SELECT sr.sr_returned_date_sk,
           'store',
           SUM(sr.sr_net_loss)
    FROM store_returns sr
    GROUP BY sr.sr_returned_date_sk
    UNION ALL
    SELECT wr.wr_returned_date_sk,
           'web',
           SUM(wr.wr_net_loss)
    FROM web_returns wr
    GROUP BY wr.wr_returned_date_sk
)
SELECT d.d_year,
       d.d_month_seq,
       s.channel,
       SUM(s.total_paid) AS total_paid,
       SUM(s.total_profit) AS total_profit,
       COALESCE(SUM(r.total_returns), 0) AS total_returns,
       SUM(s.total_paid) - COALESCE(SUM(r.total_returns), 0) AS net_sales
FROM sales_summary s
JOIN date_dim d ON s.date_sk = d.d_date_sk
LEFT JOIN returns_summary r
  ON s.channel = r.channel AND s.date_sk = r.date_sk
WHERE d.d_year BETWEEN 1999 AND 2001
GROUP BY d.d_year, d.d_month_seq, s.channel
ORDER BY d.d_year, d.d_month_seq, s.channel
