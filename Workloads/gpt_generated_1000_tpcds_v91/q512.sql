WITH promo_union AS (
    SELECT cs_order_number
    FROM catalog_sales
    WHERE cs_promo_sk = 1023
    UNION ALL
    SELECT cs_order_number
    FROM catalog_sales
    WHERE cs_promo_sk = 1057
),
high_sales AS (
    SELECT cs_order_number
    FROM catalog_sales
    WHERE cs_net_paid_inc_ship_tax > 2500
),
intersected_orders AS (
    SELECT cs_order_number FROM promo_union
    INTERSECT
    SELECT cs_order_number FROM high_sales
),
customer_agg AS (
    SELECT
        cs.cs_bill_customer_sk,
        COUNT(DISTINCT cs.cs_order_number) AS distinct_orders,
        SUM(cs.cs_net_paid_inc_ship_tax) AS total_net_paid,
        AVG(cs.cs_net_paid_inc_ship_tax) AS avg_net_paid,
        hd.hd_buy_potential,
        ib.ib_lower_bound,
        ib.ib_upper_bound
    FROM catalog_sales cs
    JOIN household_demographics hd
      ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib
      ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE cs.cs_order_number IN (SELECT cs_order_number FROM intersected_orders)
      AND regexp_like(hd.hd_buy_potential, '^\d+-\d+$')
      AND hd.hd_buy_potential LIKE '%-%'
    GROUP BY
        cs.cs_bill_customer_sk,
        hd.hd_buy_potential,
        ib.ib_lower_bound,
        ib.ib_upper_bound
)
SELECT DISTINCT
    ca.cs_bill_customer_sk,
    ca.distinct_orders,
    ca.total_net_paid,
    ca.avg_net_paid,
    (SELECT avg(cs2.cs_net_paid_inc_ship_tax) FROM catalog_sales cs2) AS global_avg_net_paid,
    CONCAT('Potential:', ca.hd_buy_potential) AS buy_potential_label,
    CONCAT('Income:', CAST(ca.ib_lower_bound AS varchar), '-', CAST(ca.ib_upper_bound AS varchar)) AS income_range,
    CAST(regexp_extract(ca.hd_buy_potential, '^(\d+)-', 1) AS integer) AS buy_potential_low,
    CAST(regexp_extract(ca.hd_buy_potential, '-(\d+)$', 1) AS integer) AS buy_potential_high
FROM customer_agg ca
WHERE EXISTS (
    SELECT 1
    FROM catalog_sales cs_ship
    JOIN household_demographics hd_ship
      ON cs_ship.cs_ship_hdemo_sk = hd_ship.hd_demo_sk
    WHERE cs_ship.cs_bill_customer_sk = ca.cs_bill_customer_sk
      AND hd_ship.hd_vehicle_count > 0
)
ORDER BY ca.total_net_paid DESC
LIMIT 100
