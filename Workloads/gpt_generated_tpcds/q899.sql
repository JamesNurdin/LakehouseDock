WITH sales_agg AS (
    SELECT
        td.t_hour,
        i.i_category,
        SUM(ss.ss_net_profit) AS total_sales_profit
    FROM store_sales ss
    JOIN time_dim td ON ss.ss_sold_time_sk = td.t_time_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    WHERE td.t_hour BETWEEN 9 AND 18
    GROUP BY td.t_hour, i.i_category
),
returns_agg AS (
    SELECT
        td.t_hour,
        i.i_category,
        SUM(sr.sr_net_loss) AS total_returns_loss
    FROM store_returns sr
    JOIN time_dim td ON sr.sr_return_time_sk = td.t_time_sk
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    WHERE td.t_hour BETWEEN 9 AND 18
    GROUP BY td.t_hour, i.i_category
)
SELECT
    COALESCE(s.t_hour, r.t_hour) AS hour_of_day,
    COALESCE(s.i_category, r.i_category) AS category,
    COALESCE(s.total_sales_profit, 0) AS total_sales_profit,
    COALESCE(r.total_returns_loss, 0) AS total_returns_loss,
    COALESCE(s.total_sales_profit, 0) - COALESCE(r.total_returns_loss, 0) AS net_profit_after_returns
FROM sales_agg s
FULL OUTER JOIN returns_agg r
    ON s.t_hour = r.t_hour AND s.i_category = r.i_category
ORDER BY hour_of_day, category
