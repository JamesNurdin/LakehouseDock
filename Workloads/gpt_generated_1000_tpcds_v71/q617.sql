WITH filtered_sales AS (
    SELECT
        cs.cs_order_number,
        cs.cs_call_center_sk,
        cs.cs_bill_addr_sk,
        cs.cs_net_paid_inc_ship,
        cc.cc_name,
        cc.cc_manager,
        ca.ca_street_number,
        ca.ca_street_type,
        ca.ca_city
    FROM catalog_sales cs
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
    WHERE regexp_like(cc.cc_manager, '^B.*')
      AND ca.ca_street_type LIKE '%Street%'
),
filtered_returns AS (
    SELECT
        cr.cr_order_number,
        cr.cr_return_amount,
        sm.sm_type
    FROM catalog_returns cr
    JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE regexp_like(sm.sm_type, '^AIR')
)
SELECT
    f.cc_name,
    substr(f.cc_name, 1, 10) AS short_cc_name,
    concat(f.ca_street_number, ' ', f.ca_street_type) AS address_desc,
    f.ca_city,
    COUNT(DISTINCT f.cs_order_number) AS orders,
    SUM(f.cs_net_paid_inc_ship) AS total_sales,
    COALESCE(SUM(r.cr_return_amount), 0) AS total_returns,
    SUM(f.cs_net_paid_inc_ship) - COALESCE(SUM(r.cr_return_amount), 0) AS net_revenue
FROM filtered_sales f
LEFT JOIN filtered_returns r ON f.cs_order_number = r.cr_order_number
GROUP BY
    f.cc_name,
    substr(f.cc_name, 1, 10),
    concat(f.ca_street_number, ' ', f.ca_street_type),
    f.ca_city
ORDER BY net_revenue DESC
LIMIT 100
