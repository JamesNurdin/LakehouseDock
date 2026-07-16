WITH sales AS (
    SELECT s.s_state AS state,
           i.i_category AS category,
           SUM(ss.ss_net_profit) AS profit
    FROM store_sales ss
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    WHERE d.d_year = 2001
    GROUP BY s.s_state, i.i_category
),
returns AS (
    SELECT s.s_state AS state,
           i.i_category AS category,
           SUM(sr.sr_net_loss) AS loss
    FROM store_returns sr
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    WHERE d.d_year = 2001
    GROUP BY s.s_state, i.i_category
)
SELECT COALESCE(s.state, r.state) AS state,
       COALESCE(s.category, r.category) AS category,
       COALESCE(s.profit, 0) - COALESCE(r.loss, 0) AS net_profit
FROM sales s
FULL OUTER JOIN returns r
  ON s.state = r.state AND s.category = r.category
ORDER BY net_profit DESC
LIMIT 100
