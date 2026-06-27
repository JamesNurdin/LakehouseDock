WITH sales_agg AS (
    SELECT
        p.p_promo_id,
        p.p_promo_name,
        t_sales.t_hour,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        SUM(ws.ws_net_profit) AS total_net_profit,
        SUM(ws.ws_quantity) AS total_quantity_sold
    FROM web_sales ws
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    JOIN time_dim t_sales ON ws.ws_sold_time_sk = t_sales.t_time_sk
    GROUP BY
        p.p_promo_id,
        p.p_promo_name,
        t_sales.t_hour
),
returns_agg AS (
    SELECT
        p.p_promo_id,
        t_return.t_hour,
        SUM(wr.wr_return_quantity) AS total_return_quantity,
        SUM(wr.wr_return_amt) AS total_return_amount
    FROM web_returns wr
    JOIN web_sales ws ON wr.wr_item_sk = ws.ws_item_sk
                     AND wr.wr_order_number = ws.ws_order_number
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    JOIN time_dim t_return ON wr.wr_returned_time_sk = t_return.t_time_sk
    GROUP BY
        p.p_promo_id,
        t_return.t_hour
)
SELECT
    s.p_promo_id,
    s.p_promo_name,
    s.t_hour,
    s.total_sales,
    s.total_net_profit,
    s.total_quantity_sold,
    COALESCE(r.total_return_quantity, 0) AS total_return_quantity,
    COALESCE(r.total_return_amount, 0) AS total_return_amount,
    CASE WHEN s.total_quantity_sold > 0
         THEN COALESCE(r.total_return_quantity, 0) * 1.0 / s.total_quantity_sold
         ELSE 0
    END AS return_rate
FROM sales_agg s
LEFT JOIN returns_agg r
  ON s.p_promo_id = r.p_promo_id
 AND s.t_hour = r.t_hour
ORDER BY s.total_sales DESC
LIMIT 100
