WITH
sales_sample AS (
    SELECT *
    FROM catalog_sales
    TABLESAMPLE BERNOULLI (10)
    WHERE cs_quantity > 0
),
branch1 AS (
    SELECT
        ss.cs_order_number,
        d_sold.d_year AS sold_year,
        d_ship.d_year AS ship_year,
        cp.cp_department,
        sm.sm_type,
        s.s_store_name,
        ca_bill.ca_state AS bill_state,
        ca_ship.ca_state AS ship_state,
        hd_bill.hd_income_band_sk AS bill_income_band,
        hd_ship.hd_income_band_sk AS ship_income_band,
        ss.cs_net_paid,
        (SELECT SUM(cs2.cs_quantity)
         FROM catalog_sales cs2
         WHERE cs2.cs_bill_customer_sk = ss.cs_bill_customer_sk) AS total_qty_by_customer
    FROM sales_sample ss
    JOIN date_dim d_sold
        ON ss.cs_sold_date_sk = d_sold.d_date_sk
    JOIN date_dim d_ship
        ON ss.cs_ship_date_sk = d_ship.d_date_sk
    JOIN catalog_page cp
        ON ss.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN ship_mode sm
        ON ss.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN store s
        ON s.s_closed_date_sk = d_ship.d_date_sk
    JOIN customer_address ca_bill
        ON ss.cs_bill_addr_sk = ca_bill.ca_address_sk
    JOIN customer_address ca_ship
        ON ss.cs_ship_addr_sk = ca_ship.ca_address_sk
    JOIN household_demographics hd_bill
        ON ss.cs_bill_hdemo_sk = hd_bill.hd_demo_sk
    JOIN household_demographics hd_ship
        ON ss.cs_ship_hdemo_sk = hd_ship.hd_demo_sk
    JOIN inventory inv
        ON inv.inv_date_sk = d_sold.d_date_sk
    WHERE d_sold.d_year = 1999
      AND sm.sm_type = 'AIR'
    GROUP BY
        ss.cs_order_number,
        d_sold.d_year,
        d_ship.d_year,
        cp.cp_department,
        sm.sm_type,
        s.s_store_name,
        ca_bill.ca_state,
        ca_ship.ca_state,
        hd_bill.hd_income_band_sk,
        hd_ship.hd_income_band_sk,
        ss.cs_net_paid,
        ss.cs_bill_customer_sk
),
branch2 AS (
    SELECT
        ss.cs_order_number,
        d_sold.d_year AS sold_year,
        d_ship.d_year AS ship_year,
        cp.cp_department,
        sm.sm_type,
        s.s_store_name,
        ca_bill.ca_state AS bill_state,
        ca_ship.ca_state AS ship_state,
        hd_bill.hd_income_band_sk AS bill_income_band,
        hd_ship.hd_income_band_sk AS ship_income_band,
        ss.cs_net_paid,
        (SELECT SUM(cs2.cs_quantity)
         FROM catalog_sales cs2
         WHERE cs2.cs_bill_customer_sk = ss.cs_bill_customer_sk) AS total_qty_by_customer
    FROM sales_sample ss
    JOIN date_dim d_sold
        ON ss.cs_sold_date_sk = d_sold.d_date_sk
    JOIN date_dim d_ship
        ON ss.cs_ship_date_sk = d_ship.d_date_sk
    JOIN catalog_page cp
        ON ss.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN ship_mode sm
        ON ss.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN store s
        ON s.s_closed_date_sk = d_ship.d_date_sk
    JOIN customer_address ca_bill
        ON ss.cs_bill_addr_sk = ca_bill.ca_address_sk
    JOIN customer_address ca_ship
        ON ss.cs_ship_addr_sk = ca_ship.ca_address_sk
    JOIN household_demographics hd_bill
        ON ss.cs_bill_hdemo_sk = hd_bill.hd_demo_sk
    JOIN household_demographics hd_ship
        ON ss.cs_ship_hdemo_sk = hd_ship.hd_demo_sk
    JOIN inventory inv
        ON inv.inv_date_sk = d_sold.d_date_sk
    WHERE d_sold.d_year = 2000
      AND sm.sm_type = 'RAIL'
    GROUP BY
        ss.cs_order_number,
        d_sold.d_year,
        d_ship.d_year,
        cp.cp_department,
        sm.sm_type,
        s.s_store_name,
        ca_bill.ca_state,
        ca_ship.ca_state,
        hd_bill.hd_income_band_sk,
        hd_ship.hd_income_band_sk,
        ss.cs_net_paid,
        ss.cs_bill_customer_sk
),
union_branches AS (
    SELECT cs_order_number, cs_net_paid FROM branch1
    UNION
    SELECT cs_order_number, cs_net_paid FROM branch2
),
orders_excluded AS (
    SELECT cs_order_number FROM branch1
    EXCEPT
    SELECT cs_order_number FROM branch2
)
SELECT
    ub.cs_order_number,
    ub.cs_net_paid,
    CASE WHEN oe.cs_order_number IS NOT NULL THEN 'EXCLUDED' ELSE 'INCLUDED' END AS order_status
FROM union_branches ub
LEFT JOIN orders_excluded oe
    ON ub.cs_order_number = oe.cs_order_number
ORDER BY ub.cs_net_paid DESC
OFFSET 0
FETCH NEXT 100 ROWS ONLY
