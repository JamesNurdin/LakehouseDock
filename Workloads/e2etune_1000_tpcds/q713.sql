WITH sales_agg AS (
    SELECT
        ws.ws_warehouse_sk,
        ws.ws_promo_sk,
        ws.ws_order_number,
        ws.ws_item_sk,
        SUM(ws.ws_net_profit) AS net_profit,
        SUM(ws.ws_ext_sales_price) AS sales_amount,
        AVG(ws.ws_ext_discount_amt) AS avg_discount,
        COUNT(*) AS line_cnt
    FROM web_sales ws
    WHERE ws.ws_sold_date_sk BETWEEN 2450800 AND 2451100
    GROUP BY ws.ws_warehouse_sk, ws.ws_promo_sk, ws.ws_order_number, ws.ws_item_sk
),
returns_agg AS (
    SELECT
        wr.wr_order_number,
        wr.wr_item_sk,
        SUM(wr.wr_return_amt_inc_tax) AS return_amount
    FROM web_returns wr
    WHERE wr.wr_returned_date_sk BETWEEN 2450800 AND 2451100
    GROUP BY wr.wr_order_number, wr.wr_item_sk
)
SELECT
    w.w_state,
    w.w_city,
    p.p_promo_name,
    COUNT(DISTINCT s.ws_order_number) AS num_orders,
    SUM(s.net_profit) AS total_net_profit,
    SUM(s.sales_amount) AS total_sales_amount,
    SUM(COALESCE(r.return_amount, 0)) AS total_return_amount,
    CASE WHEN SUM(s.sales_amount) > 0 THEN
        ROUND(SUM(COALESCE(r.return_amount, 0)) / SUM(s.sales_amount), 4)
    ELSE NULL END AS return_rate,
    AVG(s.avg_discount) AS avg_discount_amount
FROM sales_agg s
JOIN warehouse w
    ON s.ws_warehouse_sk = w.w_warehouse_sk
JOIN promotion p
    ON s.ws_promo_sk = p.p_promo_sk
LEFT JOIN returns_agg r
    ON s.ws_order_number = r.wr_order_number
    AND s.ws_item_sk = r.wr_item_sk
WHERE p.p_discount_active = 'Y'
GROUP BY w.w_state, w.w_city, p.p_promo_name
ORDER BY total_net_profit DESC
LIMIT 100
