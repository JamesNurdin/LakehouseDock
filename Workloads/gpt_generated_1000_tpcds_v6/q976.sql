WITH joined_all AS (
    SELECT
        cr.cr_returned_date_sk,
        cr.cr_return_amount,
        cr.cr_return_quantity,
        cr.cr_warehouse_sk,
        cr.cr_return_ship_cost,
        cr.cr_return_amt_inc_tax,
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        c.c_birth_year,
        c.c_birth_month,
        c.c_last_review_date,
        ca.ca_state,
        ca.ca_country,
        ws.ws_sold_date_sk,
        ws.ws_ext_sales_price,
        ws.ws_quantity,
        ws.ws_net_profit
    FROM tpcds.catalog_returns cr
    JOIN tpcds.customer c
      ON cr.cr_refunded_customer_sk = c.c_customer_sk
    JOIN tpcds.customer_address ca
      ON cr.cr_refunded_addr_sk = ca.ca_address_sk
    JOIN tpcds.web_sales ws
      ON ws.ws_bill_customer_sk = c.c_customer_sk
     AND ws.ws_bill_addr_sk = ca.ca_address_sk
    WHERE cr.cr_warehouse_sk IN (7, 11)
      AND cr.cr_return_amount > 500
      AND cr.cr_return_ship_cost BETWEEN 50 AND 2000
      AND ca.ca_state IN ('CA', 'NY')
      AND ws.ws_ext_sales_price BETWEEN 3000 AND 12000
      AND ws.ws_sold_date_sk BETWEEN 2450000 AND 2459999
)
SELECT *
FROM (
    /* First aggregation – rollup by state and first name */
    SELECT
        ca_state AS state,
        c_first_name AS person_name,
        SUM(cr_return_amount) AS total_return_amount,
        AVG(ws_ext_sales_price) AS avg_sales_price,
        COUNT(*) AS order_cnt,
        MIN(ws_net_profit) AS min_profit,
        MAX(ws_net_profit) AS max_profit,
        GROUPING(ca_state) AS g_state,
        GROUPING(c_first_name) AS g_name
    FROM joined_all
    WHERE cr_warehouse_sk = 7
      AND ca_state = 'CA'
      AND c_birth_year = 1975
    GROUP BY ROLLUP(ca_state, c_first_name)

    UNION ALL

    /* Second aggregation – cube by state and last name */
    SELECT
        ca_state AS state,
        c_last_name AS person_name,
        SUM(cr_return_amount) AS total_return_amount,
        AVG(ws_ext_sales_price) AS avg_sales_price,
        COUNT(*) AS order_cnt,
        MIN(ws_net_profit) AS min_profit,
        MAX(ws_net_profit) AS max_profit,
        GROUPING(ca_state) AS g_state,
        GROUPING(c_last_name) AS g_name
    FROM joined_all
    WHERE cr_warehouse_sk = 11
      AND ca_state = 'NY'
      AND c_birth_month = 7
    GROUP BY CUBE(ca_state, c_last_name)
) merged
ORDER BY total_return_amount DESC
LIMIT 100
