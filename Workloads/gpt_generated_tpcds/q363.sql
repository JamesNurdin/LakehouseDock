WITH
    store_sales_agg AS (
        SELECT
            ss.ss_store_sk AS store_sk,
            ss.ss_item_sk AS item_sk,
            t.t_hour AS hour,
            SUM(ss.ss_net_paid) AS total_sales,
            SUM(ss.ss_net_profit) AS total_profit
        FROM store_sales ss
        JOIN time_dim t
            ON ss.ss_sold_time_sk = t.t_time_sk
        WHERE t.t_hour BETWEEN 9 AND 17
        GROUP BY ss.ss_store_sk, ss.ss_item_sk, t.t_hour
    ),
    store_returns_agg AS (
        SELECT
            sr.sr_store_sk AS store_sk,
            sr.sr_item_sk AS item_sk,
            t.t_hour AS hour,
            SUM(sr.sr_return_amt_inc_tax) AS total_return_amount,
            SUM(sr.sr_net_loss) AS total_return_loss
        FROM store_returns sr
        JOIN time_dim t
            ON sr.sr_return_time_sk = t.t_time_sk
        WHERE t.t_hour BETWEEN 9 AND 17
        GROUP BY sr.sr_store_sk, sr.sr_item_sk, t.t_hour
    )
SELECT
    s.s_store_name,
    i.i_category,
    sales.hour,
    COALESCE(sales.total_sales, 0) AS total_sales,
    COALESCE(sales.total_profit, 0) AS total_profit,
    COALESCE(returns.total_return_amount, 0) AS total_return_amount,
    COALESCE(returns.total_return_loss, 0) AS total_return_loss,
    COALESCE(sales.total_profit, 0) - COALESCE(returns.total_return_loss, 0) AS net_profit_after_returns
FROM store_sales_agg sales
LEFT JOIN store_returns_agg returns
    ON sales.store_sk = returns.store_sk
    AND sales.item_sk = returns.item_sk
    AND sales.hour = returns.hour
JOIN store s
    ON sales.store_sk = s.s_store_sk
JOIN item i
    ON sales.item_sk = i.i_item_sk
ORDER BY net_profit_after_returns DESC
LIMIT 100
