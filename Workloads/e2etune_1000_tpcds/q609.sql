WITH promo_item_agg AS (
    SELECT
        i.i_category,
        p.p_channel_email,
        SUM(p.p_cost) AS total_promo_cost,
        AVG(i.i_current_price) AS avg_item_price,
        COUNT(DISTINCT i.i_item_id) AS distinct_item_cnt,
        COUNT(*) AS promo_count
    FROM promotion p
    JOIN item i
        ON p.p_item_sk = i.i_item_sk
    WHERE p.p_discount_active = 'Y'
      AND p.p_channel_email = 'Y'
      AND i.i_units IN ('Cup', 'Bunch')
      AND p.p_start_date_sk BETWEEN 2450000 AND 2455000
    GROUP BY i.i_category, p.p_channel_email
    HAVING SUM(p.p_cost) > 1000
)
SELECT
    i_category,
    p_channel_email,
    total_promo_cost,
    avg_item_price,
    distinct_item_cnt,
    promo_count,
    RANK() OVER (ORDER BY total_promo_cost DESC) AS promo_rank
FROM promo_item_agg
ORDER BY total_promo_cost DESC
LIMIT 50
