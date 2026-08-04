WITH catalog_part AS (
    SELECT
        cs.cs_order_number AS order_id,
        cs.cs_item_sk AS item_sk,
        cs.cs_quantity AS quantity,
        cs.cs_sales_price AS sales_price,
        cs.cs_net_paid AS net_paid,
        cs.cs_net_profit AS net_profit,
        concat(c.c_first_name, ' ', c.c_last_name) AS customer_name,
        ca.ca_city AS city,
        hd.hd_dep_count AS dep_count,
        hd.hd_vehicle_count AS vehicle_count,
        ib.ib_lower_bound AS inc_lower,
        ib.ib_upper_bound AS inc_upper,
        'catalog' AS source,
        cr.cr_return_amount AS return_amount,
        cr.cr_return_ship_cost AS return_ship_cost,
        r.r_reason_desc AS reason_desc,
        cc.cc_name AS call_center_name,
        sm.sm_type AS ship_mode_type,
        price_val AS price_component
    FROM catalog_sales cs
    JOIN catalog_returns cr
        ON cr.cr_order_number = cs.cs_order_number
    JOIN call_center cc
        ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN ship_mode sm
        ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN reason r
        ON cr.cr_reason_sk = r.r_reason_sk
    JOIN household_demographics hd
        ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN customer c
        ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN customer_address ca
        ON cs.cs_bill_addr_sk = ca.ca_address_sk
    LEFT JOIN web_page wp
        ON wp.wp_customer_sk = c.c_customer_sk
    CROSS JOIN UNNEST(ARRAY[cs.cs_sales_price, cs.cs_net_paid]) AS t(price_val)
    WHERE cs.cs_sold_date_sk BETWEEN 2450815 AND 2451215
      AND cc.cc_class = 'large'
      AND sm.sm_type = 'AIR'
      AND ib.ib_upper_bound > 80000
      AND cr.cr_return_amount > 100.00
),
store_part AS (
    SELECT
        ss.ss_ticket_number AS order_id,
        ss.ss_item_sk AS item_sk,
        ss.ss_quantity AS quantity,
        ss.ss_sales_price AS sales_price,
        ss.ss_net_paid AS net_paid,
        ss.ss_net_profit AS net_profit,
        concat(c2.c_first_name, ' ', c2.c_last_name) AS customer_name,
        ca2.ca_city AS city,
        hd2.hd_dep_count AS dep_count,
        hd2.hd_vehicle_count AS vehicle_count,
        ib2.ib_lower_bound AS inc_lower,
        ib2.ib_upper_bound AS inc_upper,
        'store' AS source,
        CAST(NULL AS decimal(7,2)) AS return_amount,
        CAST(NULL AS decimal(7,2)) AS return_ship_cost,
        CAST(NULL AS varchar) AS reason_desc,
        CAST(NULL AS varchar) AS call_center_name,
        CAST(NULL AS varchar) AS ship_mode_type,
        price_val AS price_component
    FROM store_sales ss
    FULL OUTER JOIN customer c2
        ON ss.ss_customer_sk = c2.c_customer_sk
    LEFT JOIN household_demographics hd2
        ON ss.ss_hdemo_sk = hd2.hd_demo_sk
    LEFT JOIN income_band ib2
        ON hd2.hd_income_band_sk = ib2.ib_income_band_sk
    LEFT JOIN customer_address ca2
        ON ss.ss_addr_sk = ca2.ca_address_sk
    LEFT JOIN web_page wp2
        ON wp2.wp_customer_sk = c2.c_customer_sk
    CROSS JOIN UNNEST(ARRAY[ss.ss_sales_price, ss.ss_net_paid]) AS t(price_val)
    WHERE ss.ss_sold_date_sk BETWEEN 2450815 AND 2451215
      AND ss.ss_quantity > 1
      AND ss.ss_sales_price > 20
      AND ib2.ib_lower_bound >= 50000
),
united AS (
    SELECT * FROM catalog_part
    UNION DISTINCT
    SELECT * FROM store_part
)
SELECT
    order_id,
    item_sk,
    quantity,
    sales_price,
    net_paid,
    net_profit,
    customer_name,
    city,
    dep_count,
    vehicle_count,
    inc_lower,
    inc_upper,
    source,
    return_amount,
    return_ship_cost,
    reason_desc,
    call_center_name,
    ship_mode_type,
    price_component,
    RANK() OVER (PARTITION BY source ORDER BY net_paid DESC) AS net_paid_rank,
    ROW_NUMBER() OVER (PARTITION BY source ORDER BY inc_lower) AS inc_lower_seq
FROM united
WHERE price_component IS NOT NULL
ORDER BY net_paid_rank
LIMIT 100
