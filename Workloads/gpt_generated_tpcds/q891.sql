WITH store_sales_agg AS (
    SELECT
        s.s_store_name,
        i.i_category,
        t.t_hour,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        SUM(ss.ss_net_profit) AS total_profit,
        COUNT(*) AS transaction_count
    FROM store_sales ss
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
    WHERE t.t_hour BETWEEN 9 AND 17
    GROUP BY s.s_store_name, i.i_category, t.t_hour
),
store_returns_agg AS (
    SELECT
        s.s_store_name,
        i.i_category,
        t.t_hour,
        SUM(sr.sr_return_amt_inc_tax) AS total_return_amount,
        SUM(sr.sr_net_loss) AS total_return_loss,
        COUNT(*) AS return_count
    FROM store_returns sr
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    JOIN time_dim t ON sr.sr_return_time_sk = t.t_time_sk
    WHERE t.t_hour BETWEEN 9 AND 17
    GROUP BY s.s_store_name, i.i_category, t.t_hour
)
SELECT
    ss.s_store_name,
    ss.i_category,
    ss.t_hour,
    ss.total_sales,
    ss.total_profit,
    COALESCE(r.total_return_amount, 0) AS total_return_amount,
    COALESCE(r.total_return_loss, 0) AS total_return_loss,
    ss.total_sales - COALESCE(r.total_return_amount, 0) AS net_sales,
    ss.total_profit - COALESCE(r.total_return_loss, 0) AS net_profit,
    ss.transaction_count,
    COALESCE(r.return_count, 0) AS return_count
FROM store_sales_agg ss
LEFT JOIN store_returns_agg r
    ON ss.s_store_name = r.s_store_name
   AND ss.i_category = r.i_category
   AND ss.t_hour = r.t_hour
ORDER BY ss.s_store_name, ss.i_category, ss.t_hour
