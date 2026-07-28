WITH base AS (
    SELECT
        ws.ws_order_number,
        ws.ws_net_profit,
        ws.ws_ext_sales_price,
        ws.ws_quantity,
        ws.ws_sold_date_sk,
        ws.ws_ship_date_sk,
        ws.ws_bill_hdemo_sk,
        ws.ws_ship_hdemo_sk,
        cc.cc_name,
        cc.cc_hours,
        d_sold.d_year,
        d_sold.d_date_sk AS sold_date_sk,
        d_ship.d_date_sk AS ship_date_sk,
        d_cc_open.d_date_sk AS cc_open_date_sk,
        d_cc_close.d_date_sk AS cc_close_date_sk,
        d_cp_end.d_date_sk AS cp_end_date_sk,
        hd_bill.hd_dep_count AS bill_dep_cnt,
        hd_ship.hd_dep_count AS ship_dep_cnt,
        cp.cp_type
    FROM web_sales ws
    JOIN date_dim d_sold
        ON ws.ws_sold_date_sk = d_sold.d_date_sk
    JOIN date_dim d_ship
        ON ws.ws_ship_date_sk = d_ship.d_date_sk
    JOIN household_demographics hd_bill
        ON ws.ws_bill_hdemo_sk = hd_bill.hd_demo_sk
    JOIN household_demographics hd_ship
        ON ws.ws_ship_hdemo_sk = hd_ship.hd_demo_sk
    JOIN call_center cc
        ON cc.cc_closed_date_sk = d_ship.d_date_sk
    JOIN date_dim d_cc_open
        ON cc.cc_open_date_sk = d_cc_open.d_date_sk
    JOIN date_dim d_cc_close
        ON cc.cc_closed_date_sk = d_cc_close.d_date_sk
    JOIN catalog_page cp
        ON cp.cp_start_date_sk = d_cc_open.d_date_sk
    JOIN date_dim d_cp_end
        ON cp.cp_end_date_sk = d_cp_end.d_date_sk
    WHERE d_sold.d_year = 1995
      AND cc.cc_hours = '8AM-4PM'
      AND hd_bill.hd_dep_count > 0
      AND cp.cp_type = 'electronics'
)
SELECT
    b.cc_name,
    b.d_year,
    b.bill_dep_cnt,
    SUM(b.ws_net_profit) AS total_profit,
    SUM(CASE WHEN b.ws_net_profit > 0 THEN b.ws_net_profit ELSE 0 END) AS positive_profit,
    COUNT(DISTINCT b.ws_order_number) AS order_count,
    (SELECT AVG(ws2.ws_net_profit)
       FROM web_sales ws2
       JOIN date_dim d2 ON ws2.ws_sold_date_sk = d2.d_date_sk
       WHERE d2.d_year = b.d_year) AS avg_year_profit,
    MIN(b.ws_ext_sales_price) AS min_ext_sales_price,
    MAX(b.ws_quantity) AS max_quantity
FROM base b
GROUP BY
    b.cc_name,
    b.d_year,
    b.bill_dep_cnt
ORDER BY total_profit DESC
LIMIT 100
