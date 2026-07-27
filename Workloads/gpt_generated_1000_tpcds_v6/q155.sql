WITH promo_agg AS (
   SELECT
       p_promo_name,
       COUNT(*) AS promo_cnt,
       SUM(p_cost) AS total_cost,
       AVG(p_cost) AS avg_cost
   FROM promotion
   WHERE p_channel_radio = 'N'
     AND p_response_target = 1
   GROUP BY p_promo_name
),
page_union AS (
   SELECT
       cp.cp_catalog_page_id,
       cp.cp_department,
       cp.cp_catalog_number,
       cp.cp_description,
       d_start.d_year,
       d_start.d_month_seq,
       d_end.d_year AS end_year,
       p.p_promo_name,
       p.p_cost,
       CASE WHEN p.p_cost > 1000 THEN 'High' ELSE 'Low' END AS cost_category
   FROM catalog_page cp
   JOIN date_dim d_start ON cp.cp_start_date_sk = d_start.d_date_sk
   JOIN date_dim d_end   ON cp.cp_end_date_sk = d_end.d_date_sk
   JOIN promotion p ON p.p_start_date_sk = d_start.d_date_sk
   WHERE cp.cp_department = 'Electronics'
     AND d_start.d_year = 2000
     AND d_start.d_month_seq = 1
     AND p.p_channel_radio = 'N'
   UNION ALL
   SELECT
       cp.cp_catalog_page_id,
       cp.cp_department,
       cp.cp_catalog_number,
       cp.cp_description,
       d_start.d_year,
       d_start.d_month_seq,
       d_end.d_year AS end_year,
       p.p_promo_name,
       p.p_cost,
       CASE WHEN p.p_cost > 1000 THEN 'High' ELSE 'Low' END AS cost_category
   FROM catalog_page cp
   JOIN date_dim d_start ON cp.cp_start_date_sk = d_start.d_date_sk
   JOIN date_dim d_end   ON cp.cp_end_date_sk = d_end.d_date_sk
   JOIN promotion p ON p.p_start_date_sk = d_start.d_date_sk
   WHERE cp.cp_department = 'Books'
     AND d_start.d_year = 2000
     AND d_start.d_month_seq = 1
     AND p.p_channel_radio = 'N'
)
SELECT
    pu.cp_catalog_page_id,
    pu.cp_department,
    pu.cp_catalog_number,
    pu.d_year,
    pu.end_year,
    pu.p_promo_name,
    SUM(pu.p_cost) AS total_page_promo_cost,
    COUNT(*) AS cnt_page_promo,
    MAX(CASE WHEN pu.cost_category = 'High' THEN pu.p_cost END) AS max_high_cost,
    pa.promo_cnt,
    pa.total_cost,
    pa.avg_cost,
    (SELECT COUNT(*) FROM promotion) AS total_promotions
FROM page_union pu
JOIN promo_agg pa ON pu.p_promo_name = pa.p_promo_name
WHERE EXISTS (
    SELECT 1
    FROM promotion p2
    WHERE p2.p_promo_name = pu.p_promo_name
      AND p2.p_cost > pu.p_cost
)
GROUP BY
    pu.cp_catalog_page_id,
    pu.cp_department,
    pu.cp_catalog_number,
    pu.d_year,
    pu.end_year,
    pu.p_promo_name,
    pa.promo_cnt,
    pa.total_cost,
    pa.avg_cost
HAVING SUM(pu.p_cost) > 500
ORDER BY total_page_promo_cost DESC
LIMIT 100
