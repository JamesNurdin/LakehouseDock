WITH agg AS (
    SELECT
        sm.sm_type AS ship_mode_type,
        cd.cd_gender,
        hd.hd_buy_potential,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        SUM(cs.cs_net_profit) AS total_profit,
        COUNT(*) AS order_count,
        CASE WHEN SUM(cs.cs_ext_sales_price) > 50000 THEN 'High' ELSE 'Low' END AS sales_category
    FROM catalog_sales cs
    JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE cd.cd_gender = 'M'
      AND hd.hd_buy_potential IN ('1001-5000', '>10000')
      AND p.p_channel_catalog = 'N'
      AND cs.cs_quantity > 0
    GROUP BY ROLLUP (sm.sm_type, cd.cd_gender, hd.hd_buy_potential)
),
agg_female AS (
    SELECT
        sm.sm_type AS ship_mode_type,
        cd.cd_gender,
        hd.hd_buy_potential,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        SUM(cs.cs_net_profit) AS total_profit,
        COUNT(*) AS order_count,
        CASE WHEN SUM(cs.cs_ext_sales_price) > 50000 THEN 'High' ELSE 'Low' END AS sales_category
    FROM catalog_sales cs
    JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE cd.cd_gender = 'F'
      AND hd.hd_buy_potential = '0-500'
      AND p.p_channel_catalog = 'N'
      AND cs.cs_quantity > 0
    GROUP BY ROLLUP (sm.sm_type, cd.cd_gender, hd.hd_buy_potential)
),
combined AS (
    SELECT * FROM agg
    UNION ALL
    SELECT * FROM agg_female
)
SELECT
    ship_mode_type,
    cd_gender,
    hd_buy_potential,
    SUM(total_sales) AS sum_sales,
    AVG(total_profit) AS avg_profit,
    SUM(order_count) AS total_orders,
    MAX(sales_category) AS max_sales_category
FROM combined
GROUP BY CUBE (ship_mode_type, cd_gender, hd_buy_potential)
HAVING SUM(total_sales) > 100000
ORDER BY sum_sales DESC
LIMIT 100
