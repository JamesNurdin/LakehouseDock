WITH store_sales_agg AS (
    SELECT s.s_state AS state,
           d.d_year AS year,
           d.d_moy AS month,
           s.s_store_id AS store_id,
           sum(ss.ss_net_paid) AS total_sales,
           sum(ss.ss_net_profit) AS total_profit
    FROM store_sales ss
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2002
    GROUP BY s.s_state, d.d_year, d.d_moy, s.s_store_id
), store_returns_agg AS (
    SELECT s.s_state AS state,
           d.d_year AS year,
           d.d_moy AS month,
           s.s_store_id AS store_id,
           sum(sr.sr_net_loss) AS total_return_loss
    FROM store_returns sr
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    WHERE d.d_year = 2002
    GROUP BY s.s_state, d.d_year, d.d_moy, s.s_store_id
)
SELECT ss.state,
       ss.year,
       ss.month,
       ss.store_id,
       ss.total_sales,
       COALESCE(r.total_return_loss, 0) AS total_return_loss,
       ss.total_sales - COALESCE(r.total_return_loss, 0) AS net_sales,
       ss.total_profit,
       RANK() OVER (PARTITION BY ss.state ORDER BY ss.total_sales DESC) AS sales_rank
FROM store_sales_agg ss
LEFT JOIN store_returns_agg r
  ON ss.state = r.state
 AND ss.year = r.year
 AND ss.month = r.month
 AND ss.store_id = r.store_id
ORDER BY ss.state, sales_rank
LIMIT 200
