WITH sales AS (
    SELECT
        ws.ws_item_sk,
        ws.ws_promo_sk,
        ws.ws_sold_time_sk,
        ws.ws_order_number,
        ws.ws_quantity,
        ws.ws_net_profit,
        ws.ws_ext_discount_amt,
        ws.ws_ext_sales_price
    FROM web_sales ws
    WHERE ws.ws_sold_date_sk BETWEEN 2450952 AND 2451052
      AND ws.ws_quantity > 0
),
returns AS (
    SELECT
        wr.wr_item_sk,
        wr.wr_order_number,
        wr.wr_return_quantity,
        wr.wr_net_loss
    FROM web_returns wr
    WHERE wr.wr_returned_date_sk BETWEEN 2450952 AND 2451052
)
SELECT
    i.i_category,
    i.i_brand,
    p.p_promo_id,
    CASE
        WHEN p.p_channel_tv = 'Y' THEN 'TV'
        WHEN p.p_channel_email = 'Y' THEN 'Email'
        WHEN p.p_channel_catalog = 'Y' THEN 'Catalog'
        WHEN p.p_channel_radio = 'Y' THEN 'Radio'
        WHEN p.p_channel_press = 'Y' THEN 'Press'
        WHEN p.p_channel_event = 'Y' THEN 'Event'
        WHEN p.p_channel_dmail = 'Y' THEN 'DirectMail'
        ELSE 'Other'
    END AS promo_channel,
    t.t_hour,
    SUM(s.ws_net_profit) AS total_sales_profit,
    SUM(COALESCE(r.wr_net_loss, 0)) AS total_return_loss,
    SUM(s.ws_net_profit) - SUM(COALESCE(r.wr_net_loss, 0)) AS net_profit_after_returns,
    SUM(s.ws_quantity) AS total_quantity_sold,
    SUM(COALESCE(r.wr_return_quantity, 0)) AS total_quantity_returned,
    AVG(s.ws_ext_discount_amt) AS avg_discount_amount,
    SUM(s.ws_ext_sales_price) AS total_sales_amount
FROM sales s
JOIN item i ON s.ws_item_sk = i.i_item_sk
JOIN promotion p ON s.ws_promo_sk = p.p_promo_sk
JOIN time_dim t ON s.ws_sold_time_sk = t.t_time_sk
LEFT JOIN returns r
    ON s.ws_order_number = r.wr_order_number
    AND s.ws_item_sk = r.wr_item_sk
WHERE t.t_hour BETWEEN 9 AND 21
GROUP BY
    i.i_category,
    i.i_brand,
    p.p_promo_id,
    CASE
        WHEN p.p_channel_tv = 'Y' THEN 'TV'
        WHEN p.p_channel_email = 'Y' THEN 'Email'
        WHEN p.p_channel_catalog = 'Y' THEN 'Catalog'
        WHEN p.p_channel_radio = 'Y' THEN 'Radio'
        WHEN p.p_channel_press = 'Y' THEN 'Press'
        WHEN p.p_channel_event = 'Y' THEN 'Event'
        WHEN p.p_channel_dmail = 'Y' THEN 'DirectMail'
        ELSE 'Other'
    END,
    t.t_hour
HAVING SUM(s.ws_net_profit) > 10000
ORDER BY net_profit_after_returns DESC
LIMIT 10
