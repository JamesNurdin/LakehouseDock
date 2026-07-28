WITH filtered_sales AS (
    SELECT
        cs.cs_order_number,
        cs.cs_warehouse_sk,
        cs.cs_ship_mode_sk,
        cs.cs_net_paid,
        cs.cs_sold_date_sk,
        w.w_city,
        w.w_state,
        w.w_suite_number,
        w.w_street_name,
        sm.sm_code,
        hd.hd_vehicle_count
    FROM catalog_sales cs
    JOIN warehouse w
        ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN ship_mode sm
        ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN household_demographics hd
        ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    WHERE regexp_like(w.w_suite_number, '^Suite\\s[0-9]+')
      AND sm.sm_code LIKE 'A%'
      AND hd.hd_vehicle_count >= 2
),
unioned_sales AS (
    SELECT
        cs_order_number,
        cs_warehouse_sk,
        cs_ship_mode_sk,
        cs_net_paid,
        cs_sold_date_sk,
        w_city,
        w_state,
        w_suite_number,
        w_street_name,
        sm_code,
        hd_vehicle_count
    FROM filtered_sales
    UNION ALL
    SELECT
        cs.cs_order_number,
        cs.cs_warehouse_sk,
        cs.cs_ship_mode_sk,
        cs.cs_net_paid,
        cs.cs_sold_date_sk,
        w.w_city,
        w.w_state,
        w.w_suite_number,
        w.w_street_name,
        sm.sm_code,
        hd.hd_vehicle_count
    FROM catalog_sales cs
    JOIN warehouse w
        ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN ship_mode sm
        ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN household_demographics hd
        ON cs.cs_ship_hdemo_sk = hd.hd_demo_sk
    WHERE regexp_like(w.w_suite_number, 'Suite\\s[A-Z]')
      AND sm.sm_code LIKE 'B%'
      AND hd.hd_vehicle_count <= 0
)
SELECT
    concat_ws(', ', city, state)                               AS city_state,
    sum(net_paid)                                              AS total_net_paid,
    count(*)                                                   AS order_count,
    max(suite_digits)                                          AS sample_suite_digits,
    row_number() OVER (ORDER BY sum(net_paid) DESC)           AS sales_rank
FROM (
    SELECT
        w_city                     AS city,
        w_state                    AS state,
        cs_net_paid                AS net_paid,
        regexp_extract(w_suite_number, '(\\d+)', 1) AS suite_digits
    FROM unioned_sales
) u
GROUP BY concat_ws(', ', city, state)
ORDER BY total_net_paid DESC
LIMIT 100
