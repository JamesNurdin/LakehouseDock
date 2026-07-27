/*
  goal: Calculate total net profit per year for each call center (closed) and catalog page, include the name of the call center that was open on the sale date, classify profit as positive or negative, rank the results within each year, and return the top 100 rows.
*/
WITH base AS (
    SELECT
        ws.ws_net_profit,
        d_sold.d_year,
        cc.cc_name AS cc_closed_name,
        cc_open.cc_name AS cc_open_name,
        cp.cp_catalog_page_number
    FROM tpcds.web_sales ws
    JOIN tpcds.date_dim d_sold
        ON ws.ws_sold_date_sk = d_sold.d_date_sk
    JOIN tpcds.date_dim d_ship
        ON ws.ws_ship_date_sk = d_ship.d_date_sk
    JOIN tpcds.customer cust_bill
        ON ws.ws_bill_customer_sk = cust_bill.c_customer_sk
    JOIN tpcds.customer_address ca_bill
        ON ws.ws_bill_addr_sk = ca_bill.ca_address_sk
    JOIN tpcds.customer cust_ship
        ON ws.ws_ship_customer_sk = cust_ship.c_customer_sk
    JOIN tpcds.customer_address ca_ship
        ON ws.ws_ship_addr_sk = ca_ship.ca_address_sk
    JOIN tpcds.call_center cc
        ON cc.cc_closed_date_sk = d_ship.d_date_sk
    JOIN tpcds.call_center cc_open
        ON cc_open.cc_open_date_sk = d_sold.d_date_sk
    JOIN tpcds.catalog_page cp
        ON cp.cp_start_date_sk = d_sold.d_date_sk
),
agg AS (
    SELECT
        cc_closed_name,
        cc_open_name,
        cp_catalog_page_number,
        d_year,
        SUM(ws_net_profit) AS total_profit,
        COUNT(*) AS order_cnt,
        CASE WHEN SUM(ws_net_profit) > 0 THEN 'POS' ELSE 'NEG' END AS profit_sign
    FROM base
    GROUP BY cc_closed_name, cc_open_name, cp_catalog_page_number, d_year
)
SELECT
    cc_closed_name,
    cc_open_name,
    cp_catalog_page_number,
    d_year,
    total_profit,
    order_cnt,
    profit_sign,
    ROW_NUMBER() OVER (PARTITION BY d_year ORDER BY total_profit DESC) AS profit_rank
FROM agg
ORDER BY total_profit DESC, d_year
LIMIT 100
