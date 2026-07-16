WITH promo_costs AS (
    SELECT p.p_promo_id,
           SUM(p.p_cost) AS total_cost,
           COUNT(*) AS promo_cnt,
           MIN(p.p_start_date_sk) AS min_start_sk,
           MAX(p.p_end_date_sk) AS max_end_sk
    FROM promotion p
    WHERE p.p_response_target = 1
      AND p.p_discount_active = 'Y'
    GROUP BY p.p_promo_id
),
promo_details AS (
    SELECT pc.p_promo_id,
           pc.total_cost,
           pc.promo_cnt,
           r.r_reason_desc,
           t.channel_type,
           t.channel_flag,
           td.t_hour
    FROM promo_costs pc
    JOIN promotion p ON pc.p_promo_id = p.p_promo_id
    JOIN reason r ON p.p_promo_id = r.r_reason_id
    JOIN time_dim td ON p.p_start_date_sk = td.t_time_sk
    CROSS JOIN UNNEST(
        ARRAY['email','tv','press','radio','catalog','event','dmail','demo'],
        ARRAY[p.p_channel_email, p.p_channel_tv, p.p_channel_press, p.p_channel_radio, p.p_channel_catalog, p.p_channel_event, p.p_channel_dmail, p.p_channel_demo]
    ) AS t(channel_type, channel_flag)
    WHERE t.channel_flag = 'Y'
      AND td.t_hour BETWEEN 8 AND 20
)
SELECT pd.p_promo_id,
       pd.total_cost,
       pd.promo_cnt,
       pd.r_reason_desc,
       pd.channel_type,
       pd.t_hour,
       RANK() OVER (ORDER BY pd.total_cost DESC) AS cost_rank
FROM promo_details pd
WHERE pd.total_cost > 5000
ORDER BY pd.total_cost DESC
LIMIT 50
