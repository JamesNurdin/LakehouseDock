WITH sales_agg AS (
    SELECT
        cc.cc_name,
        p.p_promo_name,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        ARRAY_AGG(DISTINCT sm.sm_carrier) AS carrier_array
    FROM tpcds.catalog_sales cs
    JOIN tpcds.call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN tpcds.promotion p ON cs.cs_promo_sk = p.p_promo_sk
    JOIN tpcds.ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN tpcds.warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN tpcds.time_dim t ON cs.cs_sold_time_sk = t.t_time_sk
    JOIN tpcds.customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
    WHERE p.p_channel_demo = 'N'
      AND p.p_response_target > 0
      AND cs.cs_ext_sales_price BETWEEN 1000 AND 15000
      AND w.w_gmt_offset BETWEEN -5.00 AND 5.00
      AND ca.ca_state = 'CA'
      AND t.t_hour BETWEEN 8 AND 20
    GROUP BY GROUPING SETS (
        (cc.cc_name, p.p_promo_name),
        (cc.cc_name),
        (p.p_promo_name)
    )
)
SELECT
    carrier,
    AVG(total_sales) AS avg_sales_per_carrier
FROM (
    SELECT cc_name, p_promo_name, total_sales, carrier_array
    FROM sales_agg
) s
CROSS JOIN UNNEST(s.carrier_array) AS u(carrier)
GROUP BY carrier
HAVING AVG(total_sales) > 5000
ORDER BY avg_sales_per_carrier DESC
LIMIT 100
