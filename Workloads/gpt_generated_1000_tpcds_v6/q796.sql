WITH sales_summary AS (
    SELECT
        cs_bill_hdemo_sk,
        cs_promo_sk,
        COUNT(*) AS order_cnt,
        SUM(cs_net_paid_inc_ship_tax) AS sum_net_paid,
        AVG(cs_net_paid_inc_ship_tax) AS avg_net_paid,
        MIN(cs_net_paid_inc_ship_tax) AS min_net_paid,
        MAX(cs_net_paid_inc_ship_tax) AS max_net_paid
    FROM catalog_sales
    WHERE cs_net_paid_inc_ship_tax > 1500
      AND cs_quantity >= 2
      AND cs_ext_discount_amt < 500
      AND cs_sold_date_sk BETWEEN 2450000 AND 2450200
      AND cs_ship_mode_sk IN (1, 2, 3)
      AND cs_call_center_sk <> 0
    GROUP BY cs_bill_hdemo_sk, cs_promo_sk
)
SELECT
    p.p_promo_name,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    hd.hd_buy_potential,
    ss.order_cnt,
    ss.sum_net_paid,
    ss.avg_net_paid,
    CASE
        WHEN ss.avg_net_paid > 3000 THEN 'High'
        WHEN ss.avg_net_paid BETWEEN 2000 AND 3000 THEN 'Medium'
        ELSE 'Low'
    END AS avg_spend_category,
    COUNT(DISTINCT hd.hd_demo_sk) AS household_count
FROM sales_summary ss
JOIN household_demographics hd
  ON ss.cs_bill_hdemo_sk = hd.hd_demo_sk
JOIN income_band ib
  ON hd.hd_income_band_sk = ib.ib_income_band_sk
JOIN promotion p
  ON ss.cs_promo_sk = p.p_promo_sk
WHERE hd.hd_dep_count <= 4
  AND hd.hd_vehicle_count > 0
  AND ib.ib_lower_bound >= 80000
  AND p.p_discount_active = 'Y'
  AND p.p_channel_email = 'Y'
  AND p.p_promo_name LIKE '%Summer%'
GROUP BY
    p.p_promo_name,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    hd.hd_buy_potential,
    ss.order_cnt,
    ss.sum_net_paid,
    ss.avg_net_paid,
    CASE
        WHEN ss.avg_net_paid > 3000 THEN 'High'
        WHEN ss.avg_net_paid BETWEEN 2000 AND 3000 THEN 'Medium'
        ELSE 'Low'
    END
ORDER BY ss.sum_net_paid DESC
LIMIT 100
