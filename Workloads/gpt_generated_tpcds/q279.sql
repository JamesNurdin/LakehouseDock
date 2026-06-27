-- Net profit by item category and hour of sale, adjusted for returns
WITH sales_agg AS (
    SELECT
        i.i_category,
        i.i_class,
        time_dim.t_hour AS t_hour,
        SUM(ss.ss_net_profit) AS total_net_profit,
        SUM(ss.ss_quantity) AS total_quantity,
        COUNT(DISTINCT ss.ss_ticket_number) AS num_sales
    FROM store_sales ss
    JOIN item i
        ON ss.ss_item_sk = i.i_item_sk
    JOIN time_dim
        ON ss.ss_sold_time_sk = time_dim.t_time_sk
    GROUP BY
        i.i_category,
        i.i_class,
        time_dim.t_hour
),
returns_agg AS (
    SELECT
        i.i_category,
        i.i_class,
        time_dim.t_hour AS t_hour,
        SUM(sr.sr_net_loss) AS total_net_loss,
        SUM(sr.sr_return_quantity) AS total_return_qty,
        COUNT(DISTINCT sr.sr_ticket_number) AS num_returns
    FROM store_returns sr
    JOIN item i
        ON sr.sr_item_sk = i.i_item_sk
    JOIN time_dim
        ON sr.sr_return_time_sk = time_dim.t_time_sk
    GROUP BY
        i.i_category,
        i.i_class,
        time_dim.t_hour
)
SELECT
    s.i_category,
    s.i_class,
    s.t_hour,
    s.total_net_profit,
    COALESCE(r.total_net_loss, 0) AS total_net_loss,
    s.total_net_profit - COALESCE(r.total_net_loss, 0) AS net_profit_after_returns,
    s.total_quantity,
    COALESCE(r.total_return_qty, 0) AS total_return_qty,
    s.num_sales,
    COALESCE(r.num_returns, 0) AS num_returns
FROM sales_agg s
LEFT JOIN returns_agg r
    ON s.i_category = r.i_category
   AND s.i_class = r.i_class
   AND s.t_hour = r.t_hour
ORDER BY
    s.i_category,
    s.i_class,
    s.t_hour
