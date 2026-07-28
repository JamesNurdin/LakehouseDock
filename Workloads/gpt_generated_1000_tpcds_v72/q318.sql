WITH dim_store AS (
   SELECT
       s.s_store_id,
       s.s_division_name,
       s.s_state,
       p.p_promo_name,
       p.p_cost,
       p.p_channel_tv,
       cc.cc_name,
       cc.cc_state,
       ws.web_site_id,
       ws.web_name,
       ws.web_state,
       d.d_year,
       d.d_quarter_name
   FROM store s
   JOIN date_dim d ON s.s_closed_date_sk = d.d_date_sk
   JOIN promotion p ON p.p_start_date_sk = d.d_date_sk
   JOIN call_center cc ON cc.cc_closed_date_sk = d.d_date_sk
   JOIN web_site ws ON ws.web_open_date_sk = d.d_date_sk
   WHERE d.d_year = 2001
     AND s.s_state = 'CA'
     AND cc.cc_state = 'CA'
     AND p.p_channel_tv = 'N'
     AND ws.web_state = 'CA'
),
agg_store AS (
   SELECT
       s_division_name AS division_name,
       s_store_id,
       SUM(p_cost) AS total_promo_cost
   FROM dim_store ds
   WHERE EXISTS (
        SELECT 1
        FROM web_page wp
        JOIN date_dim dwp ON wp.wp_creation_date_sk = dwp.d_date_sk
        WHERE wp.wp_autogen_flag = 'Y'
          AND dwp.d_year = 2001
   )
   GROUP BY s_division_name, s_store_id
)
SELECT
    division_name,
    COUNT(DISTINCT s_store_id) AS store_cnt,
    AVG(total_promo_cost) AS avg_promo_cost,
    SUM(total_promo_cost) AS sum_promo_cost
FROM agg_store
GROUP BY division_name
ORDER BY avg_promo_cost DESC
LIMIT 100
