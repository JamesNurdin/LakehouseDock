WITH sales_by_channel AS (
    SELECT
        i.i_category AS category,
        ib.ib_lower_bound AS income_lower,
        ib.ib_upper_bound AS income_upper,
        SUM(cs.cs_net_paid) AS total_net_paid,
        SUM(cs.cs_net_profit) AS total_net_profit,
        COUNT(*) AS order_cnt,
        'catalog' AS sales_channel
    FROM catalog_sales cs
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    WHERE hd.hd_vehicle_count >= 2
      AND p.p_discount_active = 'N'
    GROUP BY i.i_category, ib.ib_lower_bound, ib.ib_upper_bound

    UNION ALL

    SELECT
        i.i_category AS category,
        ib.ib_lower_bound AS income_lower,
        ib.ib_upper_bound AS income_upper,
        SUM(ss.ss_net_paid) AS total_net_paid,
        SUM(ss.ss_net_profit) AS total_net_profit,
        COUNT(*) AS order_cnt,
        'store' AS sales_channel
    FROM store_sales ss
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    WHERE hd.hd_vehicle_count >= 2
      AND p.p_discount_active = 'N'
    GROUP BY i.i_category, ib.ib_lower_bound, ib.ib_upper_bound
)
SELECT
    category,
    income_lower,
    income_upper,
    total_net_paid,
    total_net_profit,
    order_cnt,
    sales_channel
FROM sales_by_channel
ORDER BY total_net_paid DESC
LIMIT 100
