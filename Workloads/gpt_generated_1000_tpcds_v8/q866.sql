-- Goal: Analyze promotional performance by meal time, rank the top promotions by net paid amount, and provide subtotals with grouping sets while demonstrating advanced SQL features.
WITH base AS (
    SELECT
        cs.cs_sold_date_sk,
        cs.cs_sold_time_sk,
        cs.cs_promo_sk,
        cs.cs_ship_addr_sk,
        cs.cs_net_paid_inc_tax,
        cs.cs_quantity,
        p.p_promo_name,
        p.p_channel_radio,
        p.p_purpose,
        t.t_meal_time,
        t.t_second,
        ROW_NUMBER() OVER (PARTITION BY p.p_promo_name ORDER BY cs.cs_net_paid_inc_tax DESC) AS promo_rank
    FROM catalog_sales cs
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    JOIN time_dim t ON cs.cs_sold_time_sk = t.t_time_sk
    WHERE t.t_meal_time IN ('breakfast', 'lunch')
      AND t.t_second > 5
      AND p.p_channel_radio = 'N'
      AND p.p_purpose = 'Unknown'
      AND cs.cs_net_paid_inc_tax > 500
      AND cs.cs_quantity BETWEEN 1 AND 10
      AND cs.cs_ship_addr_sk NOT IN (
          SELECT cs_ship_addr_sk FROM catalog_sales WHERE cs_quantity = 0
      )
),
agg1 AS (
    SELECT
        p_promo_name,
        t_meal_time,
        COUNT(DISTINCT cs_ship_addr_sk) AS unique_ship_addrs,
        SUM(cs_net_paid_inc_tax) AS total_paid,
        AVG(cs_net_paid_inc_tax) AS avg_paid
    FROM base
    GROUP BY ROLLUP(p_promo_name, t_meal_time)   -- creates subtotals
    HAVING SUM(cs_net_paid_inc_tax) > 1000
),
detail AS (
    SELECT
        b.*,
        CASE WHEN b.promo_rank <= 3 THEN 'Top3' ELSE 'Other' END AS rank_category,
        lt.extra_info
    FROM base b
    CROSS JOIN LATERAL (
        SELECT CONCAT('Info_', CAST(b.cs_ship_addr_sk AS VARCHAR)) AS extra_info
    ) lt
),
final1 AS (
    SELECT
        d.p_promo_name,
        d.t_meal_time,
        d.rank_category,
        a.total_paid,
        a.unique_ship_addrs,
        d.promo_rank
    FROM detail d
    LEFT JOIN agg1 a
        ON (a.p_promo_name = d.p_promo_name OR a.p_promo_name IS NULL)
        AND (a.t_meal_time = d.t_meal_time OR a.t_meal_time IS NULL)
    WHERE d.rank_category = 'Top3'
)
SELECT DISTINCT
    f1.p_promo_name,
    f1.t_meal_time,
    f1.rank_category,
    f1.total_paid,
    f1.unique_ship_addrs,
    f1.promo_rank
FROM final1 f1
UNION
SELECT
    NULL AS p_promo_name,
    NULL AS t_meal_time,
    'Overall' AS rank_category,
    SUM(total_paid) OVER () AS total_paid,
    COUNT(DISTINCT unique_ship_addrs) OVER () AS unique_ship_addrs,
    NULL AS promo_rank
FROM final1
ORDER BY total_paid DESC
LIMIT 100
