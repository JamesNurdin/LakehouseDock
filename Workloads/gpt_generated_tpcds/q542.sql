WITH sales AS (
    SELECT
        ws.ws_order_number,
        ws.ws_item_sk,
        ws.ws_net_profit,
        i.i_item_id,
        i.i_category,
        i.i_class,
        i.i_brand,
        p.p_promo_name,
        sm.sm_type,
        d.d_date AS sold_date,
        d.d_year
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    LEFT JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    LEFT JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE d.d_year = 2020
),
returns AS (
    SELECT
        wr.wr_order_number,
        wr.wr_item_sk,
        wr.wr_net_loss
    FROM web_returns wr
    JOIN date_dim d_ret ON wr.wr_returned_date_sk = d_ret.d_date_sk
    WHERE d_ret.d_year = 2020
)
SELECT
    date_trunc('month', s.sold_date) AS month,
    s.i_item_id,
    s.i_category,
    s.i_class,
    s.i_brand,
    COALESCE(s.p_promo_name, 'No Promotion') AS promo_name,
    COALESCE(s.sm_type, 'Unknown') AS ship_mode_type,
    sum(s.ws_net_profit) AS total_net_profit,
    sum(COALESCE(r.wr_net_loss, 0)) AS total_return_loss,
    sum(s.ws_net_profit) - sum(COALESCE(r.wr_net_loss, 0)) AS net_profit_after_returns,
    count(DISTINCT s.ws_order_number) AS order_count
FROM sales s
LEFT JOIN returns r
    ON s.ws_order_number = r.wr_order_number
    AND s.ws_item_sk = r.wr_item_sk
GROUP BY
    date_trunc('month', s.sold_date),
    s.i_item_id,
    s.i_category,
    s.i_class,
    s.i_brand,
    COALESCE(s.p_promo_name, 'No Promotion'),
    COALESCE(s.sm_type, 'Unknown')
ORDER BY net_profit_after_returns DESC
LIMIT 10
