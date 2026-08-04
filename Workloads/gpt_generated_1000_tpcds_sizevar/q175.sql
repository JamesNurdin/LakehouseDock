WITH
    ws_base AS (
        SELECT
            ws.ws_order_number,
            ws.ws_sold_date_sk,
            ws.ws_ship_date_sk,
            ws.ws_bill_customer_sk,
            ws.ws_bill_hdemo_sk,
            ws.ws_bill_addr_sk,
            ws.ws_ship_customer_sk,
            ws.ws_ship_hdemo_sk,
            ws.ws_ship_addr_sk,
            ws.ws_web_page_sk,
            ws.ws_warehouse_sk,
            ws.ws_sales_price,
            ws.ws_ext_discount_amt,
            ARRAY[ws.ws_sales_price, ws.ws_ext_discount_amt] AS price_array
        FROM tpcds.web_sales ws
    ),
    ws_unnest AS (
        SELECT
            ws_base.*,
            pc AS price_component
        FROM ws_base
        CROSS JOIN UNNEST(ws_base.price_array) AS t(pc)
    )
SELECT
    ws_unnest.ws_order_number,
    d_sold.d_year,
    ca_bill.ca_state,
    hd_bill.hd_buy_potential,
    COUNT(DISTINCT ws_unnest.ws_order_number) AS order_cnt,
    SUM(ws_unnest.price_component) AS total_price_component,
    (SELECT SUM(wr2.wr_return_amt)
     FROM tpcds.web_returns wr2
     WHERE wr2.wr_order_number = ws_unnest.ws_order_number) AS total_wr_return_amt,
    SUM(inv.inv_quantity_on_hand) AS total_inventory,
    AVG(cs.cs_quantity) AS avg_cs_quantity,
    COUNT(DISTINCT r.r_reason_id) AS distinct_return_reasons
FROM ws_unnest
JOIN tpcds.date_dim d_sold ON ws_unnest.ws_sold_date_sk = d_sold.d_date_sk
JOIN tpcds.date_dim d_ship ON ws_unnest.ws_ship_date_sk = d_ship.d_date_sk
JOIN tpcds.customer c_bill ON ws_unnest.ws_bill_customer_sk = c_bill.c_customer_sk
JOIN tpcds.customer c_ship ON ws_unnest.ws_ship_customer_sk = c_ship.c_customer_sk
JOIN tpcds.household_demographics hd_bill ON ws_unnest.ws_bill_hdemo_sk = hd_bill.hd_demo_sk
JOIN tpcds.household_demographics hd_ship ON ws_unnest.ws_ship_hdemo_sk = hd_ship.hd_demo_sk
JOIN tpcds.customer_address ca_bill ON ws_unnest.ws_bill_addr_sk = ca_bill.ca_address_sk
JOIN tpcds.customer_address ca_ship ON ws_unnest.ws_ship_addr_sk = ca_ship.ca_address_sk
JOIN tpcds.web_page wp ON ws_unnest.ws_web_page_sk = wp.wp_web_page_sk
JOIN tpcds.warehouse w ON ws_unnest.ws_warehouse_sk = w.w_warehouse_sk
LEFT JOIN tpcds.web_returns wr ON wr.wr_order_number = ws_unnest.ws_order_number
LEFT JOIN tpcds.store_returns sr ON sr.sr_customer_sk = c_bill.c_customer_sk
                                 AND sr.sr_returned_date_sk = d_sold.d_date_sk
LEFT JOIN tpcds.reason r ON r.r_reason_sk = sr.sr_reason_sk
LEFT JOIN tpcds.inventory inv ON inv.inv_warehouse_sk = w.w_warehouse_sk
                                 AND inv.inv_date_sk = d_sold.d_date_sk
LEFT JOIN tpcds.catalog_sales cs ON cs.cs_sold_date_sk = d_sold.d_date_sk
LEFT JOIN tpcds.call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
GROUP BY
    ws_unnest.ws_order_number,
    d_sold.d_year,
    ca_bill.ca_state,
    hd_bill.hd_buy_potential
ORDER BY total_price_component DESC
LIMIT 100
