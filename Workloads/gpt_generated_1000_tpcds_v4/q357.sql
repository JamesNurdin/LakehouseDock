WITH mode_union AS (
    SELECT sm_ship_mode_sk FROM ship_mode WHERE sm_carrier = 'UPS'
    UNION ALL
    SELECT sm_ship_mode_sk FROM ship_mode WHERE sm_contract LIKE 'Y%'
),
sales_agg AS (
    SELECT
        cs.cs_ship_mode_sk,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        AVG(cs.cs_net_profit) AS avg_profit,
        COUNT(*) AS order_cnt,
        SUM(CASE WHEN cs.cs_coupon_amt > 0 THEN 1 ELSE 0 END) AS orders_with_coupon
    FROM catalog_sales cs
    WHERE cs.cs_ext_list_price > 5000
      AND cs.cs_coupon_amt > 0
      AND cs.cs_quantity BETWEEN 1 AND 10
      AND cs.cs_ship_cdemo_sk IN (1841658, 212342)
      AND cs.cs_ship_mode_sk IN (SELECT sm_ship_mode_sk FROM mode_union)
    GROUP BY cs.cs_ship_mode_sk
),
ship_filtered AS (
    SELECT
        sm.sm_ship_mode_sk,
        sm.sm_ship_mode_id,
        sm.sm_carrier,
        sm.sm_contract
    FROM ship_mode sm
    WHERE sm.sm_carrier = 'UPS'
      AND sm.sm_contract = 'yVfotg7Tio3MVhBg6Bkn'
)
SELECT
    sf.sm_ship_mode_id,
    sf.sm_carrier,
    sf.sm_contract,
    sa.total_sales,
    sa.avg_profit,
    sa.order_cnt,
    CASE WHEN sa.avg_profit > 500 THEN 'HIGH' ELSE 'LOW' END AS profit_category,
    (SELECT MAX(cs_inner.cs_ext_list_price)
     FROM catalog_sales cs_inner
     WHERE cs_inner.cs_ship_mode_sk = sf.sm_ship_mode_sk) AS max_list_price
FROM ship_filtered sf
JOIN sales_agg sa
  ON sf.sm_ship_mode_sk = sa.cs_ship_mode_sk
WHERE EXISTS (
    SELECT 1
    FROM catalog_sales cs_exist
    WHERE cs_exist.cs_ship_mode_sk = sf.sm_ship_mode_sk
      AND cs_exist.cs_net_paid_inc_tax > 10000
)
ORDER BY sa.total_sales DESC
LIMIT 100
