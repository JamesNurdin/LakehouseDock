WITH sales_with_time AS (
    SELECT ws.ws_sold_date_sk,
           ws.ws_sold_time_sk,
           ws.ws_order_number,
           ws.ws_item_sk,
           ws.ws_promo_sk,
           ws.ws_net_paid,
           ws.ws_net_profit,
           ws.ws_quantity,
           ws.ws_ext_discount_amt,
           t.t_hour,
           t.t_shift,
           t.t_meal_time
    FROM web_sales ws
    JOIN time_dim t ON ws.ws_sold_time_sk = t.t_time_sk
    WHERE ws.ws_net_paid > 0
),
returns_agg AS (
    SELECT wr.wr_order_number,
           wr.wr_item_sk,
           SUM(wr.wr_return_quantity) AS total_return_qty,
           SUM(wr.wr_return_amt) AS total_return_amt,
           SUM(wr.wr_refunded_cash) AS total_refunded_cash
    FROM web_returns wr
    GROUP BY wr.wr_order_number, wr.wr_item_sk
)
SELECT p.p_promo_id,
       p.p_purpose,
       s.t_hour,
       s.t_shift,
       COUNT(DISTINCT s.ws_order_number) AS orders,
       SUM(s.ws_net_paid) AS total_net_paid,
       SUM(s.ws_net_profit) AS total_net_profit,
       COALESCE(SUM(r.total_return_amt), 0) AS total_return_amount,
       SUM(s.ws_net_profit) - COALESCE(SUM(r.total_return_amt), 0) AS net_profit_after_returns,
       AVG(s.ws_ext_discount_amt) AS avg_discount,
       ROUND(100.0 * SUM(s.ws_net_profit) / NULLIF(SUM(s.ws_net_paid), 0), 2) AS profit_margin_percent
FROM sales_with_time s
JOIN promotion p ON s.ws_promo_sk = p.p_promo_sk
LEFT JOIN returns_agg r ON s.ws_order_number = r.wr_order_number AND s.ws_item_sk = r.wr_item_sk
WHERE p.p_channel_email = 'N'
  AND p.p_purpose IS NOT NULL
  AND s.t_hour BETWEEN 8 AND 20
GROUP BY p.p_promo_id, p.p_purpose, s.t_hour, s.t_shift
HAVING COUNT(DISTINCT s.ws_order_number) >= 10
ORDER BY total_net_profit DESC
LIMIT 100
