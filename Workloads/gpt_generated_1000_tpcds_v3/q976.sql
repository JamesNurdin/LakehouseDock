WITH ss_joined AS (
    SELECT
        ss.ss_sold_date_sk,
        ss.ss_net_profit,
        ss.ss_ext_sales_price,
        ss.ss_customer_sk,
        d_ss.d_year AS ss_year,
        c_ss.c_customer_id,
        c_ss.c_preferred_cust_flag
    FROM store_sales ss
    JOIN date_dim d_ss ON ss.ss_sold_date_sk = d_ss.d_date_sk
    JOIN customer c_ss ON ss.ss_customer_sk = c_ss.c_customer_sk
),
ws_joined AS (
    SELECT
        ws.ws_sold_date_sk,
        ws.ws_ship_date_sk,
        ws.ws_net_profit,
        ws.ws_ext_sales_price,
        ws.ws_bill_customer_sk,
        ws.ws_ship_customer_sk,
        ws.ws_warehouse_sk,
        d_ws_sold.d_year AS ws_sold_year,
        d_ws_ship.d_year AS ws_ship_year,
        c_ws_bill.c_customer_id AS bill_customer_id,
        c_ws_ship.c_customer_id AS ship_customer_id,
        w_ws.w_state AS w_state,
        w_ws.w_city AS w_city
    FROM web_sales ws
    JOIN date_dim d_ws_sold ON ws.ws_sold_date_sk = d_ws_sold.d_date_sk
    JOIN date_dim d_ws_ship ON ws.ws_ship_date_sk = d_ws_ship.d_date_sk
    JOIN customer c_ws_bill ON ws.ws_bill_customer_sk = c_ws_bill.c_customer_sk
    JOIN customer c_ws_ship ON ws.ws_ship_customer_sk = c_ws_ship.c_customer_sk
    JOIN warehouse w_ws ON ws.ws_warehouse_sk = w_ws.w_warehouse_sk
),
cp_joined AS (
    SELECT
        cp.cp_catalog_page_id,
        cp.cp_type,
        cp.cp_catalog_number,
        d_cp_start.d_year AS start_year,
        d_cp_end.d_year AS end_year,
        cp.cp_department
    FROM catalog_page cp
    JOIN date_dim d_cp_start ON cp.cp_start_date_sk = d_cp_start.d_date_sk
    JOIN date_dim d_cp_end ON cp.cp_end_date_sk = d_cp_end.d_date_sk
)
SELECT
    COALESCE(ss_joined.ss_year, ws_joined.ws_sold_year) AS year,
    ws_joined.w_state,
    COUNT(DISTINCT COALESCE(ss_joined.c_customer_id, ws_joined.bill_customer_id, ws_joined.ship_customer_id)) AS distinct_customers,
    SUM(ss_joined.ss_ext_sales_price) AS total_store_sales,
    SUM(ws_joined.ws_ext_sales_price) AS total_web_sales,
    SUM(ss_joined.ss_net_profit) + SUM(ws_joined.ws_net_profit) AS total_net_profit,
    CASE
        WHEN (SUM(ss_joined.ss_net_profit) + SUM(ws_joined.ws_net_profit)) > 500000 THEN 'High'
        WHEN (SUM(ss_joined.ss_net_profit) + SUM(ws_joined.ws_net_profit)) BETWEEN 100000 AND 500000 THEN 'Medium'
        ELSE 'Low'
    END AS profit_category,
    COUNT(DISTINCT cp_joined.cp_catalog_page_id) FILTER (WHERE cp_joined.cp_type = 'monthly') AS monthly_catalog_pages
FROM ss_joined
FULL OUTER JOIN ws_joined ON ss_joined.ss_sold_date_sk = ws_joined.ws_sold_date_sk
FULL OUTER JOIN cp_joined ON cp_joined.start_year = COALESCE(ss_joined.ss_year, ws_joined.ws_sold_year)
WHERE EXISTS (
    SELECT 1
    FROM store_sales ss2
    WHERE ss2.ss_customer_sk = ss_joined.ss_customer_sk
      AND ss2.ss_net_profit > 10000
)
  AND (ss_joined.c_preferred_cust_flag = 'Y' OR ws_joined.w_state = 'CA')
GROUP BY
    COALESCE(ss_joined.ss_year, ws_joined.ws_sold_year),
    ws_joined.w_state
ORDER BY
    total_net_profit DESC,
    year DESC
LIMIT 100
