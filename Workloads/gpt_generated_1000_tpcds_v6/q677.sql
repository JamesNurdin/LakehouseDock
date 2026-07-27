WITH cc_agg AS (
   SELECT
       'Call Center' AS source_type,
       cc.cc_mkt_desc AS description,
       d.d_year AS year,
       COUNT(DISTINCT cc.cc_call_center_id) AS cnt
   FROM call_center cc
   JOIN date_dim d ON cc.cc_closed_date_sk = d.d_date_sk
   WHERE d.d_year = 2001
     AND cc.cc_mkt_id IN (1, 2, 3)
   GROUP BY cc.cc_mkt_desc, d.d_year
),
promo_agg AS (
   SELECT
       'Promotion' AS source_type,
       p.p_promo_name AS description,
       d.d_year AS year,
       COUNT(DISTINCT p.p_promo_id) AS cnt
   FROM promotion p
   JOIN date_dim d ON p.p_start_date_sk = d.d_date_sk
   WHERE d.d_year = 2001
     AND p.p_channel_email = 'Y'
   GROUP BY p.p_promo_name, d.d_year
)
SELECT DISTINCT source_type, description, year, cnt
FROM (
   SELECT * FROM cc_agg
   UNION ALL
   SELECT * FROM promo_agg
) combined
ORDER BY year DESC, cnt DESC
LIMIT 100
