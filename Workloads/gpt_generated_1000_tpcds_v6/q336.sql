WITH base_sales AS (
    SELECT
        ws.ws_order_number,
        ws.ws_sold_date_sk,
        ws.ws_ship_date_sk,
        ws.ws_web_site_sk,
        ws.ws_promo_sk,
        ws.ws_bill_hdemo_sk,
        ws.ws_ship_hdemo_sk,
        ws.ws_quantity,
        ws.ws_ext_sales_price,
        ws.ws_net_profit
    FROM web_sales ws
)
SELECT
    s.s_store_name,
    wsit.web_name,
    p.p_promo_name,
    d_sold.d_quarter_name,
    hd_bill.hd_buy_potential,
    COUNT(DISTINCT bs.ws_order_number) AS orders_cnt,
    SUM(bs.ws_ext_sales_price) AS total_sales,
    SUM(bs.ws_net_profit) AS total_profit
FROM base_sales bs
-- sold date dimension
JOIN date_dim d_sold ON bs.ws_sold_date_sk = d_sold.d_date_sk
-- ship date dimension
JOIN date_dim d_ship ON bs.ws_ship_date_sk = d_ship.d_date_sk
-- promotion (left outer to keep sales without a promo)
LEFT JOIN promotion p ON bs.ws_promo_sk = p.p_promo_sk
-- billing household demographics
JOIN household_demographics hd_bill ON bs.ws_bill_hdemo_sk = hd_bill.hd_demo_sk
-- shipping household demographics (left outer, may be null)
LEFT JOIN household_demographics hd_ship ON bs.ws_ship_hdemo_sk = hd_ship.hd_demo_sk
-- web site information (left outer)
LEFT JOIN web_site wsit ON bs.ws_web_site_sk = wsit.web_site_sk
-- store linked through the closed‑date surrogate key
JOIN store s ON s.s_closed_date_sk = d_sold.d_date_sk
-- promotion start and end dates (left outer, may be missing)
LEFT JOIN date_dim d_p_start ON p.p_start_date_sk = d_p_start.d_date_sk
LEFT JOIN date_dim d_p_end   ON p.p_end_date_sk   = d_p_end.d_date_sk
WHERE NOT EXISTS (
    SELECT 1
    FROM web_returns wr
    WHERE wr.wr_order_number = bs.ws_order_number
)
GROUP BY
    s.s_store_name,
    wsit.web_name,
    p.p_promo_name,
    d_sold.d_quarter_name,
    hd_bill.hd_buy_potential
HAVING SUM(bs.ws_net_profit) > 0
ORDER BY total_profit DESC
LIMIT 100
