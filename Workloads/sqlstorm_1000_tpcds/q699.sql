WITH sales_agg AS (
    SELECT ss.ss_sold_date_sk AS date_sk,
           ss.ss_store_sk AS store_sk,
           SUM(ss.ss_net_profit) AS sales_profit
    FROM store_sales ss
    GROUP BY ss.ss_sold_date_sk, ss.ss_store_sk
),
returns_agg AS (
    SELECT sr.sr_returned_date_sk AS date_sk,
           sr.sr_store_sk AS store_sk,
           SUM(sr.sr_net_loss) AS return_loss
    FROM store_returns sr
    GROUP BY sr.sr_returned_date_sk, sr.sr_store_sk
),
joined AS (
    SELECT d.d_year,
           d.d_month_seq,
           s.s_store_name,
           COALESCE(sa.sales_profit, 0) AS sales_profit,
           COALESCE(ra.return_loss, 0) AS return_loss,
           COALESCE(sa.sales_profit, 0) - COALESCE(ra.return_loss, 0) AS net_profit
    FROM sales_agg sa
    JOIN date_dim d ON sa.date_sk = d.d_date_sk
    JOIN store s ON sa.store_sk = s.s_store_sk
    LEFT JOIN returns_agg ra ON ra.date_sk = d.d_date_sk AND ra.store_sk = s.s_store_sk
    WHERE d.d_year BETWEEN 1999 AND 2002
)
SELECT d_year,
       d_month_seq,
       s_store_name,
       sales_profit,
       return_loss,
       net_profit,
       rnk
FROM (
    SELECT d_year,
           d_month_seq,
           s_store_name,
           sales_profit,
           return_loss,
           net_profit,
           ROW_NUMBER() OVER (PARTITION BY d_year, d_month_seq ORDER BY net_profit DESC) AS rnk
    FROM joined
) t
WHERE rnk <= 10
ORDER BY d_year, d_month_seq, rnk
