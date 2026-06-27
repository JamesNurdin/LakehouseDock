WITH store_sales_agg AS (
    SELECT d.d_year,
           d.d_month_seq,
           sum(ss.ss_net_profit) AS store_net_profit
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE d.d_date >= DATE '2000-01-01' AND d.d_date < DATE '2001-01-01'
    GROUP BY d.d_year, d.d_month_seq
),
store_returns_agg AS (
    SELECT d.d_year,
           d.d_month_seq,
           sum(sr.sr_net_loss) AS store_net_loss
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    WHERE d.d_date >= DATE '2000-01-01' AND d.d_date < DATE '2001-01-01'
    GROUP BY d.d_year, d.d_month_seq
),
web_sales_agg AS (
    SELECT d.d_year,
           d.d_month_seq,
           ws.ws_web_site_sk,
           w.web_name,
           sum(ws.ws_net_profit) AS web_net_profit
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN web_site w ON ws.ws_web_site_sk = w.web_site_sk
    WHERE d.d_date >= DATE '2000-01-01' AND d.d_date < DATE '2001-01-01'
    GROUP BY d.d_year, d.d_month_seq, ws.ws_web_site_sk, w.web_name
),
web_returns_agg AS (
    SELECT d.d_year,
           d.d_month_seq,
           sum(wr.wr_net_loss) AS web_net_loss
    FROM web_returns wr
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    WHERE d.d_date >= DATE '2000-01-01' AND d.d_date < DATE '2001-01-01'
    GROUP BY d.d_year, d.d_month_seq
)
SELECT COALESCE(ss.d_year, sr.d_year, ws.d_year, wr.d_year) AS year,
       COALESCE(ss.d_month_seq, sr.d_month_seq, ws.d_month_seq, wr.d_month_seq) AS month_seq,
       COALESCE(ws.web_name, 'All Sites') AS web_site_name,
       COALESCE(ss.store_net_profit, 0) AS store_net_profit,
       COALESCE(sr.store_net_loss, 0) AS store_net_loss,
       COALESCE(ws.web_net_profit, 0) AS web_net_profit,
       COALESCE(wr.web_net_loss, 0) AS web_net_loss,
       (COALESCE(ss.store_net_profit, 0) - COALESCE(sr.store_net_loss, 0) +
        COALESCE(ws.web_net_profit, 0) - COALESCE(wr.web_net_loss, 0)) AS total_net
FROM store_sales_agg ss
FULL OUTER JOIN store_returns_agg sr
  ON ss.d_year = sr.d_year AND ss.d_month_seq = sr.d_month_seq
FULL OUTER JOIN web_sales_agg ws
  ON COALESCE(ss.d_year, sr.d_year) = ws.d_year
     AND COALESCE(ss.d_month_seq, sr.d_month_seq) = ws.d_month_seq
FULL OUTER JOIN web_returns_agg wr
  ON COALESCE(ss.d_year, sr.d_year, ws.d_year) = wr.d_year
     AND COALESCE(ss.d_month_seq, sr.d_month_seq, ws.d_month_seq) = wr.d_month_seq
ORDER BY year, month_seq, web_site_name
