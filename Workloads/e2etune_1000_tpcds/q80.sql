WITH sales_agg AS (
    SELECT
        p.p_promo_name AS promo_name,
        p.p_channel_tv AS channel_tv,
        p.p_channel_email AS channel_email,
        d_sold.d_quarter_name AS quarter_name,
        COUNT(DISTINCT ws.ws_order_number) AS order_cnt,
        SUM(ws.ws_quantity) AS total_qty,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        SUM(ws.ws_net_profit) AS total_profit,
        AVG(ws.ws_ext_discount_amt) AS avg_discount,
        AVG(date_diff('day', d_sold.d_date, d_ship.d_date)) AS avg_ship_delay,
        MAX(p.p_cost) AS promo_cost,
        MAX(p.p_response_target) AS response_target
    FROM web_sales ws
    JOIN date_dim d_sold ON ws.ws_sold_date_sk = d_sold.d_date_sk
    JOIN date_dim d_ship ON ws.ws_ship_date_sk = d_ship.d_date_sk
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    JOIN date_dim d_promo_start ON p.p_start_date_sk = d_promo_start.d_date_sk
    WHERE d_sold.d_year = 2021
      AND p.p_discount_active = 'Y'
      AND d_promo_start.d_year = 2021
    GROUP BY p.p_promo_name, p.p_channel_tv, p.p_channel_email, d_sold.d_quarter_name
    HAVING SUM(ws.ws_ext_sales_price) > 100000
)
SELECT
    promo_name,
    quarter_name,
    channel_tv,
    channel_email,
    order_cnt,
    total_qty,
    total_sales,
    total_profit,
    avg_discount,
    avg_ship_delay,
    promo_cost,
    response_target,
    RANK() OVER (PARTITION BY quarter_name ORDER BY total_profit DESC) AS profit_rank
FROM sales_agg
ORDER BY total_profit DESC
LIMIT 20
