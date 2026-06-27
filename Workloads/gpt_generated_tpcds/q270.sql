/*
   Net profit vs. returns per store by month (years >= 2000).
   The query aggregates:
     • Store sales net profit (store_sales.ss_net_profit)
     • Store‑level return loss (store_returns.sr_net_loss)
     • Catalog‑wide return loss (catalog_returns.cr_net_loss)
     • Web‑wide return loss (web_returns.wr_net_loss)
   and computes a net margin for each store/month.
*/
WITH ss_agg AS (
    SELECT d.d_year,
           d.d_month_seq,
           s.s_store_id,
           SUM(ss.ss_net_profit) AS total_net_profit
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    WHERE d.d_year >= 2000
    GROUP BY d.d_year, d.d_month_seq, s.s_store_id
),
sr_agg AS (
    SELECT d.d_year,
           d.d_month_seq,
           s.s_store_id,
           SUM(sr.sr_net_loss) AS total_store_return_loss
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    WHERE d.d_year >= 2000
    GROUP BY d.d_year, d.d_month_seq, s.s_store_id
),
cr_agg AS (
    SELECT d.d_year,
           d.d_month_seq,
           SUM(cr.cr_net_loss) AS total_catalog_return_loss
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    WHERE d.d_year >= 2000
    GROUP BY d.d_year, d.d_month_seq
),
wr_agg AS (
    SELECT d.d_year,
           d.d_month_seq,
           SUM(wr.wr_net_loss) AS total_web_return_loss
    FROM web_returns wr
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    WHERE d.d_year >= 2000
    GROUP BY d.d_year, d.d_month_seq
)
SELECT
    ss.d_year,
    ss.d_month_seq,
    ss.s_store_id,
    ss.total_net_profit,
    COALESCE(sr.total_store_return_loss, 0) AS total_store_return_loss,
    COALESCE(cr.total_catalog_return_loss, 0) AS total_catalog_return_loss,
    COALESCE(wr.total_web_return_loss, 0) AS total_web_return_loss,
    ss.total_net_profit
        - COALESCE(sr.total_store_return_loss, 0)
        - COALESCE(cr.total_catalog_return_loss, 0)
        - COALESCE(wr.total_web_return_loss, 0) AS net_margin
FROM ss_agg ss
LEFT JOIN sr_agg sr
    ON ss.d_year = sr.d_year
   AND ss.d_month_seq = sr.d_month_seq
   AND ss.s_store_id = sr.s_store_id
LEFT JOIN cr_agg cr
    ON ss.d_year = cr.d_year
   AND ss.d_month_seq = cr.d_month_seq
LEFT JOIN wr_agg wr
    ON ss.d_year = wr.d_year
   AND ss.d_month_seq = wr.d_month_seq
ORDER BY ss.d_year, ss.d_month_seq, ss.s_store_id
