WITH joined_data AS (
    SELECT
        sm.sm_type,
        sm.sm_code,
        sm.sm_carrier,
        w.w_city,
        w.w_state,
        ca.ca_state,
        ca.ca_zip,
        ca.ca_city,
        ARRAY[ca.ca_zip, ca.ca_city] AS address_parts,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        cs.cs_ext_sales_price,
        ws.ws_net_paid,
        ws.ws_quantity,
        ws.ws_order_number,
        cs.cs_wholesale_cost
    FROM web_sales ws
    JOIN web_returns wr
        ON wr.wr_order_number = ws.ws_order_number
    JOIN web_page wp
        ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN ship_mode sm
        ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w
        ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN customer_address ca
        ON ws.ws_bill_addr_sk = ca.ca_address_sk
    JOIN household_demographics hd
        ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN catalog_sales cs
        ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
        AND cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN catalog_page cp
        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    WHERE
        sm.sm_code IN ('AIR', 'SEA')
        AND sm.sm_carrier = 'FEDEX'
        AND w.w_state = 'CA'
        AND ca.ca_state = 'TX'
        AND ib.ib_upper_bound > 50000
        AND cs.cs_wholesale_cost > 50.00
        AND ws.ws_quantity >= 2
)
SELECT
    sm_type,
    w_city,
    ca_state,
    address_component,
    total_sales,
    avg_net_paid,
    distinct_orders,
    min_wholesale,
    max_income_upper,
    global_max_income_upper
FROM (
    SELECT
        jd.sm_type,
        jd.w_city,
        jd.ca_state,
        part AS address_component,
        SUM(jd.cs_ext_sales_price) AS total_sales,
        AVG(jd.ws_net_paid) AS avg_net_paid,
        COUNT(DISTINCT jd.ws_order_number) AS distinct_orders,
        MIN(jd.cs_wholesale_cost) AS min_wholesale,
        MAX(jd.ib_upper_bound) AS max_income_upper,
        (SELECT MAX(ib2.ib_upper_bound) FROM income_band ib2) AS global_max_income_upper
    FROM joined_data jd
    CROSS JOIN UNNEST(jd.address_parts) AS t(part)
    GROUP BY jd.sm_type, jd.w_city, jd.ca_state, part, jd.ib_upper_bound

    UNION DISTINCT

    SELECT
        jd.sm_type,
        jd.w_city,
        jd.ca_state,
        part AS address_component,
        SUM(jd.cs_ext_sales_price) AS total_sales,
        AVG(jd.ws_net_paid) AS avg_net_paid,
        COUNT(DISTINCT jd.ws_order_number) AS distinct_orders,
        MIN(jd.cs_wholesale_cost) AS min_wholesale,
        MAX(jd.ib_upper_bound) AS max_income_upper,
        (SELECT MAX(ib2.ib_upper_bound) FROM income_band ib2) AS global_max_income_upper
    FROM joined_data jd
    CROSS JOIN UNNEST(jd.address_parts) AS t(part)
    WHERE jd.sm_type = 'REGULAR'
    GROUP BY jd.sm_type, jd.w_city, jd.ca_state, part, jd.ib_upper_bound
) AS unioned
ORDER BY total_sales DESC
LIMIT 100
