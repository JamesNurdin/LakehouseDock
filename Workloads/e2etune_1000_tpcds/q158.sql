WITH sales_agg AS (
    SELECT
        cc.cc_city AS city,
        sm.sm_type AS sm_type,
        SUM(cs.cs_net_paid) AS total_net_paid,
        SUM(cs.cs_ext_sales_price) AS total_sales_price,
        AVG(cs.cs_coupon_amt) AS avg_coupon_amt,
        COUNT(DISTINCT cs.cs_order_number) AS distinct_orders
    FROM catalog_sales cs
    JOIN call_center cc
        ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN ship_mode sm
        ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE cc.cc_state IN ('TN', 'GA')
      AND cc.cc_gmt_offset = -5.00
      AND cc.cc_rec_start_date >= DATE '2000-01-01'
      AND cs.cs_sold_date_sk BETWEEN 2451545 AND 2451910
    GROUP BY cc.cc_city, sm.sm_type
    HAVING SUM(cs.cs_net_paid) > 5000
)
SELECT
    city,
    sm_type,
    total_net_paid,
    total_sales_price,
    avg_coupon_amt,
    distinct_orders,
    RANK() OVER (PARTITION BY sm_type ORDER BY total_net_paid DESC) AS city_rank_within_mode
FROM sales_agg
ORDER BY sm_type, city_rank_within_mode
