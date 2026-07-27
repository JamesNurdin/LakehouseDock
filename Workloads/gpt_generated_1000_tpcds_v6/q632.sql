/* goal: calculate total profit and sales count per store and item category for items whose formulation starts with digits and contains the word 'goldenrod', linked to stores whose name includes 'Market' and promotions with purpose 'Unknown'. Also extract the leading numeric part of the formulation and summarize income‑band ranges. */
WITH filtered_sales AS (
    SELECT
        ss.ss_store_sk,
        ss.ss_item_sk,
        ss.ss_net_profit,
        i.i_category,
        i.i_formulation,
        i.i_brand,
        i.i_color,
        s.s_store_name,
        s.s_city,
        p.p_purpose,
        ib.ib_lower_bound,
        ib.ib_upper_bound
    FROM store_sales ss
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE regexp_like(i.i_formulation, '^\\d+')
      AND i.i_formulation LIKE '%goldenrod%'
      AND s.s_store_name LIKE '%Market%'
      AND p.p_purpose = 'Unknown'
      AND ib.ib_upper_bound >= 130000
)
SELECT
    s_store_name,
    i_category,
    concat(i_brand, '-', i_color) AS brand_color,
    CAST(regexp_extract(i_formulation, '(\\d+)', 1) AS integer) AS first_number_int,
    SUM(ss_net_profit) AS total_profit,
    COUNT(*) AS sales_transactions,
    AVG(CAST(regexp_extract(i_formulation, '(\\d+)', 1) AS integer)) AS avg_extracted_number,
    SUBSTR(s_city, 1, 3) AS city_prefix,
    MIN(ib_lower_bound) AS min_income_lower,
    MAX(ib_upper_bound) AS max_income_upper
FROM filtered_sales
GROUP BY
    s_store_name,
    i_category,
    concat(i_brand, '-', i_color),
    CAST(regexp_extract(i_formulation, '(\\d+)', 1) AS integer),
    SUBSTR(s_city, 1, 3)
ORDER BY total_profit DESC
LIMIT 100
