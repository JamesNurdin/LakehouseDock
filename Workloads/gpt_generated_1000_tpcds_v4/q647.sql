WITH distinct_promos AS (
    SELECT DISTINCT p_promo_sk, p_promo_id
    FROM promotion
    WHERE p_discount_active = 'Y'
      AND p_channel_email = 'Y'
),
cs_agg AS (
    SELECT
        cs_bill_hdemo_sk AS hd_demo_sk,
        cs_promo_sk,
        SUM(cs_net_paid) AS total_net_paid,
        SUM(cs_quantity) AS total_quantity,
        COUNT(DISTINCT cs_order_number) AS distinct_orders
    FROM catalog_sales
    WHERE cs_sales_price > 20.00
      AND cs_quantity >= 2
      AND cs_net_paid_inc_ship > 500.00
    GROUP BY cs_bill_hdemo_sk, cs_promo_sk
)
SELECT
    hd.hd_demo_sk,
    hd.hd_income_band_sk,
    hd.hd_vehicle_count,
    dp.p_promo_id,
    CASE WHEN hd.hd_vehicle_count > 2 THEN 'High' ELSE 'Low' END AS vehicle_category,
    cs_agg.total_net_paid,
    cs_agg.total_quantity,
    cs_agg.distinct_orders,
    SUM(ss.ss_net_profit) AS store_net_profit,
    AVG(ss.ss_sales_price) AS avg_store_sales_price,
    COUNT(DISTINCT ss.ss_ticket_number) AS distinct_tickets
FROM cs_agg
JOIN distinct_promos dp
    ON cs_agg.cs_promo_sk = dp.p_promo_sk
JOIN household_demographics hd
    ON cs_agg.hd_demo_sk = hd.hd_demo_sk
JOIN store_sales ss
    ON ss.ss_hdemo_sk = hd.hd_demo_sk
   AND ss.ss_promo_sk = dp.p_promo_sk
WHERE hd.hd_income_band_sk BETWEEN 5 AND 15
  AND hd.hd_dep_count <= 5
  AND ss.ss_list_price BETWEEN 30.00 AND 120.00
  AND ss.ss_quantity > 1
  AND ss.ss_ext_wholesale_cost < 5000.00
  AND hd.hd_vehicle_count IN (0, 1, 2, 3, 4)
GROUP BY
    hd.hd_demo_sk,
    hd.hd_income_band_sk,
    hd.hd_vehicle_count,
    dp.p_promo_id,
    CASE WHEN hd.hd_vehicle_count > 2 THEN 'High' ELSE 'Low' END,
    cs_agg.total_net_paid,
    cs_agg.total_quantity,
    cs_agg.distinct_orders
ORDER BY cs_agg.total_net_paid DESC
LIMIT 100
