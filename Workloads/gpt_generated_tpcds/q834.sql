WITH sales_agg AS (
    SELECT
        i.i_brand AS brand,
        t.t_hour AS hour_of_day,
        SUM(ws.ws_ext_sales_price) AS total_sales_amount,
        SUM(ws.ws_quantity) AS total_sales_quantity,
        SUM(ws.ws_net_profit) AS total_sales_net_profit
    FROM web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN time_dim t ON ws.ws_sold_time_sk = t.t_time_sk
    GROUP BY i.i_brand, t.t_hour
),
returns_agg AS (
    SELECT
        i.i_brand AS brand,
        t.t_hour AS hour_of_day,
        SUM(wr.wr_return_amt) AS total_return_amount,
        SUM(wr.wr_return_quantity) AS total_return_quantity,
        SUM(wr.wr_net_loss) AS total_return_net_loss
    FROM web_returns wr
    JOIN item i ON wr.wr_item_sk = i.i_item_sk
    JOIN time_dim t ON wr.wr_returned_time_sk = t.t_time_sk
    GROUP BY i.i_brand, t.t_hour
)
SELECT
    COALESCE(s.brand, r.brand) AS brand,
    COALESCE(s.hour_of_day, r.hour_of_day) AS hour_of_day,
    COALESCE(s.total_sales_amount, 0) AS total_sales_amount,
    COALESCE(s.total_sales_quantity, 0) AS total_sales_quantity,
    COALESCE(s.total_sales_net_profit, 0) AS total_sales_net_profit,
    COALESCE(r.total_return_amount, 0) AS total_return_amount,
    COALESCE(r.total_return_quantity, 0) AS total_return_quantity,
    COALESCE(r.total_return_net_loss, 0) AS total_return_net_loss
FROM sales_agg s
FULL OUTER JOIN returns_agg r
    ON s.brand = r.brand AND s.hour_of_day = r.hour_of_day
ORDER BY brand, hour_of_day
