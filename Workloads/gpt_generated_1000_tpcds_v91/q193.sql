WITH base AS (
    SELECT
        i.i_category,
        ca_bill.ca_county AS billing_county,
        ws.ws_ext_sales_price,
        sr.sr_return_amt_inc_tax,
        ws.ws_order_number,
        sr.sr_ticket_number,
        w.w_warehouse_sq_ft,
        w2.w_warehouse_sq_ft AS w2_warehouse_sq_ft,
        i_extra.i_wholesale_cost,
        ca_bill2.ca_gmt_offset
    FROM store_returns sr
    JOIN item i
        ON sr.sr_item_sk = i.i_item_sk
    JOIN customer_address ca_sr
        ON sr.sr_addr_sk = ca_sr.ca_address_sk
    JOIN web_sales ws
        ON ws.ws_item_sk = i.i_item_sk
    JOIN customer_address ca_bill
        ON ws.ws_bill_addr_sk = ca_bill.ca_address_sk
    JOIN customer_address ca_ship
        ON ws.ws_ship_addr_sk = ca_ship.ca_address_sk
    JOIN warehouse w
        ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN item i_extra
        ON ws.ws_item_sk = i_extra.i_item_sk
    JOIN warehouse w2
        ON ws.ws_warehouse_sk = w2.w_warehouse_sk
    JOIN customer_address ca_bill2
        ON ws.ws_bill_addr_sk = ca_bill2.ca_address_sk
)
SELECT
    i_category,
    billing_county,
    SUM(ws_ext_sales_price) AS total_sales_amount,
    SUM(sr_return_amt_inc_tax) AS total_return_amount,
    COUNT(DISTINCT ws_order_number) AS num_orders,
    COUNT(DISTINCT sr_ticket_number) AS num_returns,
    AVG(w_warehouse_sq_ft) AS avg_warehouse_sqft,
    AVG(w2_warehouse_sq_ft) AS avg_warehouse_sqft_2,
    AVG(i_wholesale_cost) AS avg_item_wholesale_cost,
    AVG(ca_gmt_offset) AS avg_bill_gmt_offset,
    (SELECT COUNT(*) FROM item i_sub WHERE i_sub.i_category = base.i_category) AS category_item_count
FROM base
GROUP BY ROLLUP (i_category, billing_county)
LIMIT 100
