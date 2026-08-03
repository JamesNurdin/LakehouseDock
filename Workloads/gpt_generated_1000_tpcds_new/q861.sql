WITH filtered_sales AS (
    SELECT
        cs_sold_date_sk,
        cs_sold_time_sk,
        cs_ship_date_sk,
        cs_bill_customer_sk,
        cs_bill_cdemo_sk,
        cs_bill_hdemo_sk,
        cs_bill_addr_sk,
        cs_ship_customer_sk,
        cs_ship_cdemo_sk,
        cs_ship_hdemo_sk,
        cs_ship_addr_sk,
        cs_call_center_sk,
        cs_catalog_page_sk,
        cs_ship_mode_sk,
        cs_warehouse_sk,
        cs_item_sk,
        cs_promo_sk,
        cs_order_number,
        cs_quantity,
        cs_wholesale_cost,
        cs_list_price,
        cs_sales_price,
        cs_ext_discount_amt,
        cs_ext_sales_price,
        cs_ext_wholesale_cost,
        cs_ext_list_price,
        cs_ext_tax,
        cs_coupon_amt,
        cs_ext_ship_cost,
        cs_net_paid,
        cs_net_paid_inc_tax,
        cs_net_paid_inc_ship,
        cs_net_paid_inc_ship_tax,
        cs_net_profit
    FROM tpcds.catalog_sales
    WHERE cs_ext_ship_cost > 500
      AND cs_wholesale_cost BETWEEN 5 AND 100
      AND cs_quantity >= 2
      AND cs_net_profit > 0
),
--- keys for EXCEPT -----------------------------------
 bill_keys AS (
    SELECT cs_bill_addr_sk FROM filtered_sales
),
 ship_keys AS (
    SELECT cs_ship_addr_sk FROM filtered_sales
),
 addr_not_shipped AS (
    SELECT cs_bill_addr_sk FROM bill_keys
    EXCEPT
    SELECT cs_ship_addr_sk FROM ship_keys
),
--- join billing side ----------------------------------
joined_bill AS (
    SELECT
        cs.cs_order_number,
        cs.cs_bill_addr_sk,
        cs.cs_bill_hdemo_sk,
        cs.cs_net_paid,
        ca.ca_state,
        ca.ca_location_type,
        hd.hd_income_band_sk,
        hd.hd_vehicle_count
    FROM filtered_sales cs
    LEFT JOIN tpcds.customer_address ca
        ON cs.cs_bill_addr_sk = ca.ca_address_sk
    LEFT JOIN tpcds.household_demographics hd
        ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
),
--- join shipping side ---------------------------------
joined_ship AS (
    SELECT
        cs.cs_order_number,
        cs.cs_ship_addr_sk,
        cs.cs_ship_hdemo_sk,
        cs.cs_net_paid,
        ca.ca_state AS ship_state,
        ca.ca_location_type AS ship_loc_type,
        hd.hd_income_band_sk AS ship_income_band,
        hd.hd_vehicle_count AS ship_vehicle_count
    FROM filtered_sales cs
    LEFT JOIN tpcds.customer_address ca
        ON cs.cs_ship_addr_sk = ca.ca_address_sk
    LEFT JOIN tpcds.household_demographics hd
        ON cs.cs_ship_hdemo_sk = hd.hd_demo_sk
),
--- aggregation with GROUPING SETS --------------------
aggregated AS (
    SELECT
        COALESCE(jb.cs_order_number, js.cs_order_number) AS order_number,
        COALESCE(jb.ca_state, js.ship_state) AS state,
        CASE
            WHEN COALESCE(jb.hd_income_band_sk, js.ship_income_band) >= 10 THEN 'HIGH'
            ELSE 'LOW'
        END AS income_category,
        SUM(COALESCE(jb.cs_net_paid, 0) + COALESCE(js.cs_net_paid, 0)) AS total_paid,
        CASE WHEN an.cs_bill_addr_sk IS NOT NULL THEN TRUE ELSE FALSE END AS bill_addr_unmatched
    FROM joined_bill jb
    FULL OUTER JOIN joined_ship js
        ON jb.cs_order_number = js.cs_order_number
    LEFT JOIN addr_not_shipped an
        ON jb.cs_bill_addr_sk = an.cs_bill_addr_sk
    GROUP BY GROUPING SETS (
        (jb.cs_order_number, jb.ca_state, jb.hd_income_band_sk, an.cs_bill_addr_sk),
        (js.cs_order_number, js.ship_state, js.ship_income_band, an.cs_bill_addr_sk)
    )
    HAVING SUM(COALESCE(jb.cs_net_paid, 0) + COALESCE(js.cs_net_paid, 0)) > 1000
),
--- window functions -----------------------------------
ranked AS (
    SELECT
        order_number,
        state,
        income_category,
        total_paid,
        bill_addr_unmatched,
        ROW_NUMBER() OVER (PARTITION BY state ORDER BY total_paid DESC) AS rn_state,
        RANK() OVER (ORDER BY total_paid DESC) AS overall_rank
    FROM aggregated
)
SELECT
    order_number,
    state,
    income_category,
    total_paid,
    bill_addr_unmatched,
    rn_state,
    overall_rank
FROM ranked
LIMIT 100
