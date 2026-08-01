SELECT
    ws_site.web_name AS website_name,
    i.i_category AS item_category,
    cd_bill.cd_gender AS gender,
    d_sold.d_year AS sales_year,
    d_sold.d_moy AS sales_month,
    ib.ib_lower_bound AS income_lower,
    ib.ib_upper_bound AS income_upper,
    SUM(ws.ws_ext_sales_price) AS total_sales_amount,
    SUM(ws.ws_net_profit) AS total_profit,
    COUNT(DISTINCT ws.ws_order_number) AS distinct_orders
FROM web_sales ws
JOIN date_dim d_sold
    ON ws.ws_sold_date_sk = d_sold.d_date_sk
JOIN time_dim t
    ON ws.ws_sold_time_sk = t.t_time_sk
JOIN date_dim d_ship
    ON ws.ws_ship_date_sk = d_ship.d_date_sk
JOIN item i
    ON ws.ws_item_sk = i.i_item_sk
JOIN customer c_bill
    ON ws.ws_bill_customer_sk = c_bill.c_customer_sk
JOIN customer_demographics cd_bill
    ON ws.ws_bill_cdemo_sk = cd_bill.cd_demo_sk
JOIN household_demographics hd_bill
    ON ws.ws_bill_hdemo_sk = hd_bill.hd_demo_sk
JOIN income_band ib
    ON hd_bill.hd_income_band_sk = ib.ib_income_band_sk
JOIN warehouse w
    ON ws.ws_warehouse_sk = w.w_warehouse_sk
JOIN web_site ws_site
    ON ws.ws_web_site_sk = ws_site.web_site_sk
JOIN date_dim d_site_open
    ON ws_site.web_open_date_sk = d_site_open.d_date_sk
JOIN date_dim d_site_close
    ON ws_site.web_close_date_sk = d_site_close.d_date_sk
WHERE t.t_hour BETWEEN 9 AND 17
  AND ws.ws_ext_sales_price > 0
GROUP BY
    ws_site.web_name,
    i.i_category,
    cd_bill.cd_gender,
    d_sold.d_year,
    d_sold.d_moy,
    ib.ib_lower_bound,
    ib.ib_upper_bound
ORDER BY total_sales_amount DESC
LIMIT 100
