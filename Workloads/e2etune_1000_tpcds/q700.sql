SELECT
    w.w_warehouse_id,
    w.w_city,
    w.w_state,
    COUNT(DISTINCT ws.ws_order_number) AS order_cnt,
    SUM(ws.ws_ext_sales_price) AS total_sales,
    SUM(ws.ws_net_profit) AS total_profit,
    AVG(ws.ws_ext_discount_amt) AS avg_discount,
    SUM(ws.ws_quantity) AS total_quantity,
    RANK() OVER (ORDER BY SUM(ws.ws_net_profit) DESC) AS profit_rank
FROM web_sales ws
JOIN warehouse w
    ON ws.ws_warehouse_sk = w.w_warehouse_sk
WHERE ws.ws_sold_date_sk BETWEEN 2450000 AND 2450100
  AND ws.ws_ext_sales_price > (SELECT ib_upper_bound FROM income_band WHERE ib_income_band_sk = 3)
  AND w.w_gmt_offset BETWEEN -5.00 AND 5.00
GROUP BY w.w_warehouse_id, w.w_city, w.w_state
HAVING SUM(ws.ws_net_profit) > 10000
ORDER BY profit_rank
LIMIT 20
