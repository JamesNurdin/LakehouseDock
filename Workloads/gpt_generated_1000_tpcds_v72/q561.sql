WITH overall_avg AS (
    SELECT avg(cs_coupon_amt) AS avg_coupon
    FROM catalog_sales
)
SELECT *
FROM (
    SELECT
        p.p_promo_id,
        sum(cs.cs_ext_sales_price) AS total_sales,
        avg(cs.cs_net_profit) AS avg_profit,
        CASE WHEN avg(cs.cs_net_profit) > 1000 THEN 'HIGH' ELSE 'LOW' END AS profit_category,
        oa.avg_coupon AS overall_avg_coupon
    FROM catalog_sales cs
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    CROSS JOIN overall_avg oa
    WHERE p.p_channel_tv = 'Y'
      AND cs.cs_coupon_amt > 0
    GROUP BY p.p_promo_id, oa.avg_coupon

    UNION ALL

    SELECT
        p.p_promo_id,
        sum(cs.cs_ext_sales_price) AS total_sales,
        avg(cs.cs_net_profit) AS avg_profit,
        CASE WHEN avg(cs.cs_net_profit) > 1000 THEN 'HIGH' ELSE 'LOW' END AS profit_category,
        oa.avg_coupon AS overall_avg_coupon
    FROM catalog_sales cs
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    CROSS JOIN overall_avg oa
    WHERE p.p_channel_catalog = 'Y'
      AND cs.cs_coupon_amt = 0
      AND EXISTS (
          SELECT 1 FROM promotion p2
          WHERE p2.p_promo_sk = cs.cs_promo_sk
            AND p2.p_channel_radio = 'Y'
      )
    GROUP BY p.p_promo_id, oa.avg_coupon
) combined
ORDER BY total_sales DESC
LIMIT 100
