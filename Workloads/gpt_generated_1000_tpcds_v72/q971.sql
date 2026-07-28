WITH base_data AS (
    SELECT
        cr.cr_returned_date_sk,
        d_ret.d_year AS return_year,
        cc.cc_division,
        cc.cc_division_name,
        cr.cr_net_loss,
        r.r_reason_desc,
        ca_refund.ca_address_sk AS refund_addr_sk,
        ca_return.ca_address_sk AS returning_addr_sk,
        ws.ws_net_profit,
        ws.ws_order_number,
        ws.ws_quantity,
        ws.ws_ext_sales_price,
        d_sold.d_year AS sold_year,
        d_ship.d_year AS ship_year,
        ca_bill.ca_address_sk AS bill_addr_sk,
        ca_ship.ca_address_sk AS ship_addr_sk,
        cc.cc_closed_date_sk,
        d_closed.d_year AS closed_year,
        cc.cc_open_date_sk,
        d_open.d_year AS open_year
    FROM catalog_returns cr
    JOIN date_dim d_ret
      ON cr.cr_returned_date_sk = d_ret.d_date_sk
    JOIN customer_address ca_refund
      ON cr.cr_refunded_addr_sk = ca_refund.ca_address_sk
    JOIN customer_address ca_return
      ON cr.cr_returning_addr_sk = ca_return.ca_address_sk
    JOIN call_center cc
      ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN reason r
      ON cr.cr_reason_sk = r.r_reason_sk
    JOIN date_dim d_closed
      ON cc.cc_closed_date_sk = d_closed.d_date_sk
    JOIN date_dim d_open
      ON cc.cc_open_date_sk = d_open.d_date_sk
    JOIN web_sales ws
      ON ws.ws_sold_date_sk = d_ret.d_date_sk
    JOIN date_dim d_sold
      ON ws.ws_sold_date_sk = d_sold.d_date_sk
    JOIN date_dim d_ship
      ON ws.ws_ship_date_sk = d_ship.d_date_sk
    JOIN customer_address ca_bill
      ON ws.ws_bill_addr_sk = ca_bill.ca_address_sk
    JOIN customer_address ca_ship
      ON ws.ws_ship_addr_sk = ca_ship.ca_address_sk
)
SELECT
    return_year,
    cc_division_name,
    SUM(cr_net_loss) AS total_net_loss,
    SUM(ws_net_profit) AS total_net_profit,
    COUNT(DISTINCT bill_addr_sk) AS distinct_bill_addresses,
    CASE WHEN SUM(ws_net_profit) > 0 THEN 'PROFIT' ELSE 'LOSS' END AS profit_flag
FROM base_data
GROUP BY ROLLUP (return_year, cc_division_name)
HAVING SUM(cr_net_loss) > 1000
ORDER BY return_year NULLS LAST, cc_division_name
LIMIT 100
