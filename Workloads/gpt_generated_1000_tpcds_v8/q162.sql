WITH cr AS (
        SELECT
            cr_returned_date_sk,
            cr_returned_time_sk,
            cr_item_sk,
            cr_return_amount,
            cr_net_loss,
            cr_refunded_addr_sk,
            cr_returning_addr_sk
        FROM catalog_returns
        WHERE cr_return_amount > 0
    ),
    ws AS (
        SELECT
            ws_sold_date_sk,
            ws_sold_time_sk,
            ws_item_sk,
            ws_ext_sales_price,
            ws_net_profit,
            ws_bill_addr_sk,
            ws_ship_addr_sk,
            ws_web_site_sk,
            ws_order_number
        FROM web_sales
        WHERE ws_ext_sales_price > 0
    )
SELECT
    ds_sale.d_year,
    ds_sale.d_month_seq,
    i_cr.i_category,
    ws_site.web_name,
    ca_refund.ca_location_type,
    SUM(ws.ws_ext_sales_price)          AS total_sales,
    SUM(cr.cr_return_amount)            AS total_returns,
    COUNT(DISTINCT ws.ws_order_number)  AS distinct_orders,
    AVG(ws.ws_net_profit)               AS avg_profit,
    MIN(cr.cr_return_amount)            AS min_return_amount,
    MAX(ws.ws_ext_sales_price)          AS max_sale_amount
FROM cr
JOIN date_dim dr_return
  ON cr.cr_returned_date_sk = dr_return.d_date_sk
JOIN time_dim tt_return
  ON cr.cr_returned_time_sk = tt_return.t_time_sk
JOIN item i_cr
  ON cr.cr_item_sk = i_cr.i_item_sk
JOIN customer_address ca_refund
  ON cr.cr_refunded_addr_sk = ca_refund.ca_address_sk
JOIN customer_address ca_returning
  ON cr.cr_returning_addr_sk = ca_returning.ca_address_sk
JOIN ws
  ON cr.cr_item_sk = ws.ws_item_sk
JOIN date_dim ds_sale
  ON ws.ws_sold_date_sk = ds_sale.d_date_sk
JOIN time_dim tt_sale
  ON ws.ws_sold_time_sk = tt_sale.t_time_sk
JOIN item i_ws
  ON ws.ws_item_sk = i_ws.i_item_sk
JOIN customer_address ca_bill
  ON ws.ws_bill_addr_sk = ca_bill.ca_address_sk
JOIN customer_address ca_ship
  ON ws.ws_ship_addr_sk = ca_ship.ca_address_sk
JOIN web_site ws_site
  ON ws.ws_web_site_sk = ws_site.web_site_sk
JOIN date_dim d_site_open
  ON ws_site.web_open_date_sk = d_site_open.d_date_sk
JOIN date_dim d_site_close
  ON ws_site.web_close_date_sk = d_site_close.d_date_sk
WHERE dr_return.d_year = 2001
  AND ds_sale.d_year = 2001
  AND ca_refund.ca_location_type = 'apartment'
  AND ca_bill.ca_state = 'CA'
  AND i_cr.i_brand = 'Brand#12'
  AND ws_site.web_tax_percentage = 0.06
  AND tt_sale.t_hour BETWEEN 9 AND 17
GROUP BY
    ds_sale.d_year,
    ds_sale.d_month_seq,
    i_cr.i_category,
    ws_site.web_name,
    ca_refund.ca_location_type
ORDER BY total_sales DESC
LIMIT 100
