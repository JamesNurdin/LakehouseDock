WITH sales_agg AS (
    SELECT
        store.s_store_name AS store_name,
        date_trunc('month', date_dim.d_date) AS month_start,
        sum(store_sales.ss_net_profit) AS total_net_profit,
        sum(store_sales.ss_ext_sales_price) AS total_sales,
        sum(store_sales.ss_quantity) AS total_quantity
    FROM store_sales
    JOIN store
        ON store_sales.ss_store_sk = store.s_store_sk
    JOIN date_dim
        ON store_sales.ss_sold_date_sk = date_dim.d_date_sk
    WHERE date_dim.d_year = 2020
    GROUP BY store.s_store_name, date_trunc('month', date_dim.d_date)
),
returns_agg AS (
    SELECT
        store.s_store_name AS store_name,
        date_trunc('month', date_dim.d_date) AS month_start,
        sum(store_returns.sr_net_loss) AS total_net_loss,
        sum(store_returns.sr_return_amt) AS total_return_amount,
        sum(store_returns.sr_return_quantity) AS total_return_quantity
    FROM store_returns
    JOIN store
        ON store_returns.sr_store_sk = store.s_store_sk
    JOIN date_dim
        ON store_returns.sr_returned_date_sk = date_dim.d_date_sk
    WHERE date_dim.d_year = 2020
    GROUP BY store.s_store_name, date_trunc('month', date_dim.d_date)
)
SELECT
    sales_agg.store_name,
    sales_agg.month_start,
    sales_agg.total_net_profit,
    coalesce(returns_agg.total_net_loss, 0) AS total_net_loss,
    sales_agg.total_net_profit - coalesce(returns_agg.total_net_loss, 0) AS net_contribution,
    sales_agg.total_sales,
    sales_agg.total_quantity
FROM sales_agg
LEFT JOIN returns_agg
    ON sales_agg.store_name = returns_agg.store_name
    AND sales_agg.month_start = returns_agg.month_start
ORDER BY net_contribution DESC
LIMIT 50
