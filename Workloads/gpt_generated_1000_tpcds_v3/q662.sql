/* goal: Summarize net profit and coupon behavior per promotion and customer gender for catalog promotions whose name contains 'Discount', demonstrating string functions (REGEXP_LIKE, LIKE, CONCAT, SUBSTRING, REGEXP_EXTRACT) */
WITH promo_sales_agg AS (
    SELECT
        p.p_promo_id,
        p.p_promo_name,
        cd.cd_gender,
        COUNT(*) AS sales_count,
        SUM(cs.cs_net_profit) AS total_net_profit,
        AVG(cs.cs_coupon_amt) AS avg_coupon_amt
    FROM catalog_sales cs
    JOIN promotion p
        ON cs.cs_promo_sk = p.p_promo_sk
    JOIN customer_demographics cd
        ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    WHERE REGEXP_LIKE(p.p_promo_name, '(?i)Discount')
      AND p.p_channel_catalog = 'Y'
      AND cd.cd_gender LIKE 'F%'
      AND p.p_promo_id LIKE 'PR%'
    GROUP BY p.p_promo_id, p.p_promo_name, cd.cd_gender
)
SELECT
    promo_sales_agg.p_promo_id,
    promo_sales_agg.p_promo_name,
    promo_sales_agg.cd_gender,
    promo_sales_agg.sales_count,
    promo_sales_agg.total_net_profit,
    promo_sales_agg.avg_coupon_amt,
    CONCAT(promo_sales_agg.p_promo_id, '-', promo_sales_agg.cd_gender) AS promo_gender_key,
    SUBSTRING(promo_sales_agg.p_promo_name, 1, 15) AS promo_name_prefix,
    REGEXP_EXTRACT(promo_sales_agg.p_promo_id, '\\d+') AS promo_id_digits
FROM promo_sales_agg
ORDER BY promo_sales_agg.total_net_profit DESC
LIMIT 100
