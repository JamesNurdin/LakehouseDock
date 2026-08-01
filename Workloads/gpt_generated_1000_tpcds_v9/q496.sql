SELECT
    d_sold.d_year AS sold_year,
    d_sold.d_month_seq AS sold_month,
    sm.sm_carrier,
    SUM(ws.ws_net_paid) AS total_net_paid,
    SUM(ws.ws_ext_discount_amt) AS total_discount,
    SUM(wr.wr_return_amt) AS total_return_amount,
    COUNT(DISTINCT ws.ws_order_number) AS distinct_orders,
    COUNT(DISTINCT ws.ws_item_sk) AS distinct_items
FROM
    tpcds.web_sales ws
JOIN
    tpcds.date_dim d_sold
      ON ws.ws_sold_date_sk = d_sold.d_date_sk
JOIN
    tpcds.date_dim d_ship
      ON ws.ws_ship_date_sk = d_ship.d_date_sk
JOIN
    tpcds.ship_mode sm
      ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
JOIN
    tpcds.warehouse w
      ON ws.ws_warehouse_sk = w.w_warehouse_sk
JOIN
    tpcds.promotion p
      ON ws.ws_promo_sk = p.p_promo_sk
JOIN
    tpcds.customer_address ca_bill
      ON ws.ws_bill_addr_sk = ca_bill.ca_address_sk
JOIN
    tpcds.customer_address ca_ship
      ON ws.ws_ship_addr_sk = ca_ship.ca_address_sk
JOIN
    tpcds.web_returns wr
      ON ws.ws_order_number = wr.wr_order_number
     AND ws.ws_item_sk = wr.wr_item_sk
JOIN
    tpcds.date_dim d_return
      ON wr.wr_returned_date_sk = d_return.d_date_sk
JOIN
    tpcds.reason r
      ON wr.wr_reason_sk = r.r_reason_sk
WHERE
    sm.sm_carrier IN ('MSC', 'USPS')
    AND r.r_reason_desc = 'Not working any more'
    AND EXISTS (
        SELECT 1
        FROM tpcds.call_center cc
        WHERE cc.cc_open_date_sk = d_sold.d_date_sk
          AND cc.cc_country = 'United States'
    )
    AND EXISTS (
        SELECT 1
        FROM tpcds.catalog_page cp
        WHERE cp.cp_start_date_sk <= d_sold.d_date_sk
          AND cp.cp_end_date_sk >= d_sold.d_date_sk
          AND cp.cp_type = 'Retail'
    )
GROUP BY
    ROLLUP (d_sold.d_year, d_sold.d_month_seq, sm.sm_carrier)
ORDER BY
    sold_year,
    sold_month,
    sm.sm_carrier
LIMIT 100
