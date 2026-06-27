WITH sales_agg AS (
    SELECT
        s.s_store_id,
        s.s_store_name,
        d_sales.d_year,
        d_sales.d_moy,
        SUM(ss.ss_net_profit) AS total_sales_net_profit
    FROM store_sales ss
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN date_dim d_sales ON ss.ss_sold_date_sk = d_sales.d_date_sk
    WHERE d_sales.d_year = 2001
    GROUP BY s.s_store_id, s.s_store_name, d_sales.d_year, d_sales.d_moy
),
returns_agg AS (
    SELECT
        s.s_store_id,
        d_returns.d_year,
        d_returns.d_moy,
        SUM(sr.sr_net_loss) AS total_returns_net_loss
    FROM store_returns sr
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    JOIN date_dim d_returns ON sr.sr_returned_date_sk = d_returns.d_date_sk
    WHERE d_returns.d_year = 2001
    GROUP BY s.s_store_id, d_returns.d_year, d_returns.d_moy
)
SELECT
    sales_agg.s_store_name,
    sales_agg.d_year,
    sales_agg.d_moy,
    sales_agg.total_sales_net_profit,
    COALESCE(returns_agg.total_returns_net_loss, 0) AS total_returns_net_loss,
    sales_agg.total_sales_net_profit - COALESCE(returns_agg.total_returns_net_loss, 0) AS net_profit_after_returns,
    ROW_NUMBER() OVER (ORDER BY sales_agg.total_sales_net_profit - COALESCE(returns_agg.total_returns_net_loss, 0) DESC) AS profit_rank
FROM sales_agg
LEFT JOIN returns_agg
    ON sales_agg.s_store_id = returns_agg.s_store_id
    AND sales_agg.d_year = returns_agg.d_year
    AND sales_agg.d_moy = returns_agg.d_moy
ORDER BY net_profit_after_returns DESC
LIMIT 50
