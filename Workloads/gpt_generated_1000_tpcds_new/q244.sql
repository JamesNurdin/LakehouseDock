WITH
    sales AS (
        SELECT
            ws.ws_order_number,
            ws.ws_sold_date_sk,
            ws.ws_sold_time_sk,
            ws.ws_ship_date_sk,
            ws.ws_item_sk,
            ws.ws_quantity,
            ws.ws_sales_price,
            ws.ws_ext_discount_amt,
            ws.ws_net_profit,
            ws.ws_ship_mode_sk,
            ws.ws_promo_sk,
            ws.ws_bill_hdemo_sk,
            ws.ws_ship_hdemo_sk,
            ws.ws_bill_customer_sk,
            ws.ws_warehouse_sk
        FROM web_sales ws
        WHERE ws.ws_quantity > 0
    ),
    returns AS (
        SELECT
            wr.wr_order_number,
            wr.wr_returned_date_sk,
            wr.wr_return_quantity,
            wr.wr_return_amt,
            wr.wr_item_sk
        FROM web_returns wr
    )
SELECT
    d_sold.d_year,
    sm.sm_ship_mode_id,
    s.s_store_name,
    COUNT(DISTINCT sales.ws_order_number) AS orders_cnt,
    SUM(sales.ws_quantity) AS total_qty_sold,
    SUM(sales.ws_sales_price * sales.ws_quantity) AS total_sales_amount,
    SUM(CASE WHEN sales.ws_ext_discount_amt > 0 THEN sales.ws_ext_discount_amt ELSE 0 END) AS total_discount,
    AVG(sales.ws_net_profit) AS avg_net_profit,
    SUM(COALESCE(inv_l.on_hand, 0)) AS total_inventory_on_hand,
    COUNT(DISTINCT returns.wr_order_number) AS returns_cnt,
    SUM(returns.wr_return_amt) AS total_return_amount,
    CASE
        WHEN AVG(sales.ws_net_profit) > 1500 THEN 'HIGH'
        WHEN AVG(sales.ws_net_profit) BETWEEN 500 AND 1500 THEN 'MEDIUM'
        ELSE 'LOW'
    END AS profit_category,
    (SELECT COUNT(DISTINCT ws_bill_customer_sk) FROM web_sales) AS total_customers
FROM sales
JOIN date_dim d_sold ON sales.ws_sold_date_sk = d_sold.d_date_sk
JOIN time_dim t_sold ON sales.ws_sold_time_sk = t_sold.t_time_sk
JOIN date_dim d_ship ON sales.ws_ship_date_sk = d_ship.d_date_sk
JOIN ship_mode sm ON sales.ws_ship_mode_sk = sm.sm_ship_mode_sk
JOIN promotion p ON sales.ws_promo_sk = p.p_promo_sk
JOIN date_dim d_promo_start ON p.p_start_date_sk = d_promo_start.d_date_sk
JOIN date_dim d_promo_end ON p.p_end_date_sk = d_promo_end.d_date_sk
JOIN household_demographics hd_bill ON sales.ws_bill_hdemo_sk = hd_bill.hd_demo_sk
JOIN household_demographics hd_ship ON sales.ws_ship_hdemo_sk = hd_ship.hd_demo_sk
JOIN income_band ib ON hd_bill.hd_income_band_sk = ib.ib_income_band_sk
JOIN store s ON s.s_closed_date_sk = d_ship.d_date_sk
LEFT JOIN returns ON sales.ws_order_number = returns.wr_order_number
LEFT JOIN LATERAL (
    SELECT inv_quantity_on_hand AS on_hand
    FROM inventory inv
    JOIN date_dim d_inv ON inv.inv_date_sk = d_inv.d_date_sk
    WHERE inv.inv_item_sk = sales.ws_item_sk
      AND d_inv.d_year = d_sold.d_year
    ORDER BY d_inv.d_date_sk DESC
    FETCH FIRST 1 ROWS ONLY
) AS inv_l ON TRUE
WHERE d_sold.d_year = 2000
  AND d_sold.d_month_seq BETWEEN 1200 AND 1220
  AND p.p_channel_tv = 'N'
  AND p.p_channel_demo = 'N'
  AND sm.sm_type = 'AIR'
  AND ib.ib_lower_bound >= 30001
  AND ib.ib_upper_bound <= 120000
  AND sales.ws_order_number IN (
        SELECT ws_order_number FROM web_sales WHERE ws_net_profit > 2000
        INTERSECT
        SELECT wr_order_number FROM web_returns WHERE wr_return_amt > 0
    )
GROUP BY
    d_sold.d_year,
    sm.sm_ship_mode_id,
    s.s_store_name
HAVING COUNT(DISTINCT sales.ws_order_number) > 5
ORDER BY total_sales_amount DESC
LIMIT 100
