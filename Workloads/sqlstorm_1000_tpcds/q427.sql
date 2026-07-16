WITH sales AS (
    SELECT
        d.d_year,
        s.s_state,
        i.i_category,
        SUM(ss.ss_net_paid) AS total_sales,
        SUM(ss.ss_net_profit) AS total_profit
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    GROUP BY d.d_year, s.s_state, i.i_category
), returns AS (
    SELECT
        d.d_year,
        s.s_state,
        i.i_category,
        SUM(sr.sr_return_amt) AS total_returns,
        SUM(sr.sr_net_loss) AS total_loss
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    GROUP BY d.d_year, s.s_state, i.i_category
)
SELECT
    COALESCE(s.d_year, r.d_year) AS sales_year,
    COALESCE(s.s_state, r.s_state) AS state,
    COALESCE(s.i_category, r.i_category) AS category,
    COALESCE(s.total_sales, 0) AS total_sales,
    COALESCE(s.total_profit, 0) AS total_profit,
    COALESCE(r.total_returns, 0) AS total_returns,
    COALESCE(r.total_loss, 0) AS total_loss,
    (COALESCE(s.total_profit, 0) - COALESCE(r.total_loss, 0)) / NULLIF(COALESCE(s.total_sales, 0) + COALESCE(r.total_returns, 0), 0) AS profit_margin
FROM sales s
FULL OUTER JOIN returns r
    ON s.d_year = r.d_year
   AND s.s_state = r.s_state
   AND s.i_category = r.i_category
ORDER BY sales_year, state, category
