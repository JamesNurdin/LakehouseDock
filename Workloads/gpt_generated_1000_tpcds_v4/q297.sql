WITH
    d_sold AS (
        SELECT d_date_sk, d_date, d_year
        FROM tpcds.date_dim
        WHERE d_year = 2001
    ),
    d_ship AS (
        SELECT d_date_sk, d_date
        FROM tpcds.date_dim
    ),
    cust_bill AS (
        SELECT c_customer_sk, c_first_name, c_last_name, c_preferred_cust_flag
        FROM tpcds.customer
    ),
    cust_ship AS (
        SELECT c_customer_sk, c_first_name AS ship_first_name, c_last_name AS ship_last_name
        FROM tpcds.customer
    ),
    addr_bill AS (
        SELECT ca_address_sk, ca_city, ca_state, ca_zip
        FROM tpcds.customer_address
    ),
    addr_ship AS (
        SELECT ca_address_sk, ca_city AS ship_city, ca_state AS ship_state, ca_zip AS ship_zip
        FROM tpcds.customer_address
    )
SELECT
    i.i_category,
    sm.sm_type,
    s.s_store_name,
    cc.cc_name,
    SUM(cs.cs_net_profit) AS total_profit,
    COUNT(DISTINCT cs.cs_order_number) AS order_cnt,
    MIN(d_sold.d_date) AS first_sold_date,
    MAX(d_ship.d_date) AS last_ship_date,
    COUNT(DISTINCT cust_bill.c_customer_sk) AS distinct_bill_customers,
    COUNT(DISTINCT cust_ship.c_customer_sk) AS distinct_ship_customers
FROM tpcds.catalog_sales cs
INNER JOIN d_sold ON cs.cs_sold_date_sk = d_sold.d_date_sk
INNER JOIN d_ship ON cs.cs_ship_date_sk = d_ship.d_date_sk
INNER JOIN cust_bill ON cs.cs_bill_customer_sk = cust_bill.c_customer_sk
INNER JOIN cust_ship ON cs.cs_ship_customer_sk = cust_ship.c_customer_sk
INNER JOIN addr_bill ON cs.cs_bill_addr_sk = addr_bill.ca_address_sk
INNER JOIN addr_ship ON cs.cs_ship_addr_sk = addr_ship.ca_address_sk
INNER JOIN tpcds.call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
INNER JOIN tpcds.catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
INNER JOIN tpcds.ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
INNER JOIN tpcds.item i ON cs.cs_item_sk = i.i_item_sk
INNER JOIN tpcds.promotion p ON cs.cs_promo_sk = p.p_promo_sk
INNER JOIN tpcds.store s ON s.s_closed_date_sk = d_ship.d_date_sk
GROUP BY
    i.i_category,
    sm.sm_type,
    s.s_store_name,
    cc.cc_name
ORDER BY total_profit DESC
LIMIT 100
