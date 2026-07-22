WITH sales_agg AS (
    SELECT
        sm.sm_ship_mode_id,
        sm.sm_type,
        sm.sm_code,
        p.p_promo_name,
        p.p_channel_tv,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        AVG(cs.cs_quantity) AS avg_quantity,
        COUNT(*) AS order_count,
        MIN(cs.cs_ext_sales_price) AS min_sales,
        MAX(cs.cs_ext_sales_price) AS max_sales
    FROM catalog_sales cs
    JOIN ship_mode sm
        ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN promotion p
        ON cs.cs_promo_sk = p.p_promo_sk
    WHERE cs.cs_ship_cdemo_sk IN (53024, 186754)
      AND cs.cs_ship_customer_sk = 2922254
      AND cs.cs_list_price BETWEEN 20 AND 200
      AND sm.sm_code = 'AIR'
      AND sm.sm_contract = 'O9V6oF8RJnLMmZYd1'
      AND p.p_channel_tv = 'N'
      AND p.p_response_target >= 1
    GROUP BY sm.sm_ship_mode_id, sm.sm_type, sm.sm_code, p.p_promo_name, p.p_channel_tv
)
SELECT
    sm_ship_mode_id,
    sm_type,
    sm_code,
    p_promo_name,
    total_sales,
    avg_quantity,
    order_count,
    min_sales,
    max_sales,
    RANK() OVER (PARTITION BY sm_type ORDER BY total_sales DESC) AS sales_rank_by_type
FROM sales_agg
ORDER BY total_sales DESC, sm_type
LIMIT 100
