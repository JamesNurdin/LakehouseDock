WITH base AS (
    SELECT
        d.d_year,
        cc.cc_name,
        sm.sm_type,
        cr.cr_return_amount,
        ws.ws_ext_sales_price,
        wr.wr_fee,
        sr.sr_fee
    FROM tpcds.catalog_returns cr
    JOIN tpcds.date_dim d
        ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN tpcds.call_center cc
        ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN tpcds.ship_mode sm
        ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN tpcds.customer c
        ON cr.cr_refunded_customer_sk = c.c_customer_sk
    JOIN tpcds.customer_address ca
        ON cr.cr_refunded_addr_sk = ca.ca_address_sk
    JOIN tpcds.store_returns sr
        ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN tpcds.web_sales ws
        ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN tpcds.web_returns wr
        ON wr.wr_returned_date_sk = d.d_date_sk
        AND wr.wr_order_number = ws.ws_order_number
    WHERE d.d_year = 2002
      AND cc.cc_state = 'CA'
      AND sm.sm_type = 'AIR'
      AND cr.cr_return_amount > 1000
      AND ws.ws_ext_sales_price > 5000
)
SELECT
    d_year,
    cc_name,
    sm_type,
    SUM(cr_return_amount)        AS total_return_amount,
    SUM(ws_ext_sales_price)      AS total_sales_amount,
    COUNT(*)                     AS transaction_cnt,
    AVG(wr_fee)                  AS avg_web_return_fee,
    MAX(sr_fee)                  AS max_store_return_fee
FROM base
GROUP BY GROUPING SETS (
    (d_year, cc_name, sm_type),
    (d_year, cc_name),
    (d_year)
)
LIMIT 100
