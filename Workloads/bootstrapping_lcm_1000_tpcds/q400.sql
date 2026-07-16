SELECT
    cr.cr_order_number,
    cr.cr_return_quantity,
    cr.cr_return_amount,
    cr.cr_fee,
    cr.cr_reversed_charge,
    cr.cr_net_loss,
    d_return.d_year AS return_year,
    d_return.d_month_seq AS return_month_seq,
    ws.ws_order_number,
    ws.ws_quantity,
    ws.ws_sales_price,
    ws.ws_ext_sales_price,
    ws.ws_ext_discount_amt,
    ws.ws_ext_list_price,
    ws.ws_ext_tax,
    ws.ws_ext_wholesale_cost,
    ws.ws_net_paid,
    ws.ws_net_paid_inc_tax,
    ws.ws_net_paid_inc_ship,
    ws.ws_net_paid_inc_ship_tax,
    ws.ws_net_profit,
    ws.ws_ship_mode_sk,
    ws.ws_promo_sk,
    ws.ws_warehouse_sk,
    ws.ws_ship_hdemo_sk,
    ws.ws_ship_cdemo_sk,
    ws.ws_bill_hdemo_sk,
    ws.ws_bill_cdemo_sk,
    ws.ws_ship_customer_sk,
    ws.ws_bill_customer_sk,
    ws.ws_ship_addr_sk,
    ws.ws_bill_addr_sk,
    ws.ws_sold_time_sk,
    ws.ws_web_page_sk,
    ws.ws_web_site_sk,
    ws.ws_ship_date_sk,
    ws.ws_sold_date_sk,
    d_sold.d_year AS sold_year,
    d_sold.d_month_seq AS sold_month_seq,
    d_ship.d_year AS ship_year,
    d_ship.d_month_seq AS ship_month_seq,
    s.s_store_name,
    s.s_city,
    s.s_state,
    s.s_tax_percentage,
    d_store.d_year AS store_closed_year,
    d_store.d_month_seq AS store_closed_month_seq,
    ws2.web_name,
    ws2.web_city,
    ws2.web_state,
    ws2.web_tax_percentage,
    d_open.d_year AS site_open_year,
    d_open.d_month_seq AS site_open_month_seq,
    d_close.d_year AS site_close_year,
    d_close.d_month_seq AS site_close_month_seq
FROM catalog_returns cr
JOIN date_dim d_return
    ON cr.cr_returned_date_sk = d_return.d_date_sk
JOIN web_sales ws
    ON ws.ws_sold_date_sk = d_return.d_date_sk
JOIN date_dim d_sold
    ON ws.ws_sold_date_sk = d_sold.d_date_sk
JOIN date_dim d_ship
    ON ws.ws_ship_date_sk = d_ship.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = d_return.d_date_sk
JOIN date_dim d_store
    ON s.s_closed_date_sk = d_store.d_date_sk
JOIN web_site ws2
    ON ws.ws_web_site_sk = ws2.web_site_sk
JOIN date_dim d_open
    ON ws2.web_open_date_sk = d_open.d_date_sk
JOIN date_dim d_close
    ON ws2.web_close_date_sk = d_close.d_date_sk
WHERE cr.cr_net_loss > 0
  AND ws.ws_net_profit > 0
  AND d_return.d_year = 2002
ORDER BY cr.cr_return_amount DESC
LIMIT 100
