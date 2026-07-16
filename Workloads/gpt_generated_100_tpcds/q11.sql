WITH web_sales_data AS (
    SELECT
        ws.ws_sold_date_sk,
        ws.ws_item_sk,
        ws.ws_promo_sk,
        ws.ws_ship_mode_sk,
        ws.ws_order_number,
        ws.ws_net_profit,
        ws.ws_net_paid,
        ws.ws_ext_ship_cost,
        ws.ws_ext_sales_price
    FROM web_sales ws
)
SELECT
    d.d_year,
    d.d_moy,
    i.i_category,
    p.p_promo_name,
    sm.sm_type,
    sum(ws_data.ws_net_profit) AS total_net_profit,
    sum(ws_data.ws_net_paid) AS total_net_paid,
    avg(ws_data.ws_ext_ship_cost) AS avg_ship_cost,
    sum(ws_data.ws_ext_sales_price) AS total_sales_price,
    count(distinct ws_data.ws_order_number) AS order_count,
    sum(ws_data.ws_net_profit) / nullif(sum(ws_data.ws_net_paid), 0) AS profit_margin
FROM web_sales_data ws_data
JOIN date_dim d ON ws_data.ws_sold_date_sk = d.d_date_sk
JOIN item i ON ws_data.ws_item_sk = i.i_item_sk
JOIN promotion p ON ws_data.ws_promo_sk = p.p_promo_sk
JOIN ship_mode sm ON ws_data.ws_ship_mode_sk = sm.sm_ship_mode_sk
WHERE d.d_year = 2020
  AND i.i_category = 'Electronics'
GROUP BY d.d_year, d.d_moy, i.i_category, p.p_promo_name, sm.sm_type
ORDER BY d.d_year, d.d_moy, total_net_profit DESC
