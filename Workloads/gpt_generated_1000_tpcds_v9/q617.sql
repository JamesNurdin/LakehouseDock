WITH
    -- First scenario: billing addresses on avenues, air ship mode, warehouse 3, CA store, specific return date
    scenario_one AS (
        SELECT
            store.s_store_name,
            ca_bill.ca_state,
            sm.sm_type,
            COUNT(DISTINCT cs.cs_order_number) AS order_cnt,
            SUM(cs.cs_ext_sales_price) AS total_sales,
            AVG(sr.sr_return_amt) AS avg_return_amount,
            MAX(cs.cs_net_profit) AS max_profit,
            MIN(cs.cs_net_profit) AS min_profit
        FROM catalog_sales cs
        JOIN customer_address ca_bill ON cs.cs_bill_addr_sk = ca_bill.ca_address_sk
        JOIN customer_address ca_ship ON cs.cs_ship_addr_sk = ca_ship.ca_address_sk
        JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
        JOIN store_returns sr ON sr.sr_addr_sk = ca_bill.ca_address_sk
        JOIN store ON sr.sr_store_sk = store.s_store_sk
        WHERE ca_bill.ca_street_type = 'Ave'
          AND sm.sm_type = 'AIR'
          AND cs.cs_warehouse_sk = 3
          AND sr.sr_returned_date_sk = 2452242
          AND store.s_state = 'CA'
        GROUP BY store.s_store_name, ca_bill.ca_state, sm.sm_type
        HAVING COUNT(DISTINCT cs.cs_order_number) > 5
    ),
    -- Second scenario: billing addresses on parkways, ground ship mode, warehouse 8, TX store, another return date
    scenario_two AS (
        SELECT
            store.s_store_name,
            ca_bill.ca_state,
            sm.sm_type,
            COUNT(DISTINCT cs.cs_order_number) AS order_cnt,
            SUM(cs.cs_ext_sales_price) AS total_sales,
            AVG(sr.sr_return_amt) AS avg_return_amount,
            MAX(cs.cs_net_profit) AS max_profit,
            MIN(cs.cs_net_profit) AS min_profit
        FROM catalog_sales cs
        JOIN customer_address ca_bill ON cs.cs_bill_addr_sk = ca_bill.ca_address_sk
        JOIN customer_address ca_ship ON cs.cs_ship_addr_sk = ca_ship.ca_address_sk
        JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
        JOIN store_returns sr ON sr.sr_addr_sk = ca_bill.ca_address_sk
        JOIN store ON sr.sr_store_sk = store.s_store_sk
        WHERE ca_bill.ca_street_type = 'Pkwy'
          AND sm.sm_type = 'GROUND'
          AND cs.cs_warehouse_sk = 8
          AND sr.sr_returned_date_sk = 2451953
          AND store.s_state = 'TX'
        GROUP BY store.s_store_name, ca_bill.ca_state, sm.sm_type
        HAVING COUNT(DISTINCT cs.cs_order_number) > 5
    )
SELECT *
FROM scenario_one
INTERSECT
SELECT *
FROM scenario_two
LIMIT 100
