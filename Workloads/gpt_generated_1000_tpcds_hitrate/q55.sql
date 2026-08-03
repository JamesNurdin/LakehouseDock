WITH filtered_sales AS (
    SELECT
        cs.cs_order_number,
        cs.cs_net_paid,
        p.p_promo_id,
        p.p_promo_name,
        regexp_extract(p.p_promo_name, '(\\d{4})', 1) AS promo_year,
        sm.sm_type,
        cp.cp_department,
        cp.cp_type,
        cp.cp_description,
        d.d_year
    FROM catalog_sales cs
    JOIN date_dim d
      ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN promotion p
      ON cs.cs_promo_sk = p.p_promo_sk
    JOIN ship_mode sm
      ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN catalog_page cp
      ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    WHERE d.d_year = 2002
      AND regexp_like(p.p_promo_name, '\\d{4}')
      AND cp.cp_description LIKE 'Elect%'
)
SELECT
    p.p_promo_id,
    p.p_promo_name,
    regexp_extract(p.p_promo_name, '(\\d{4})', 1) AS promo_year,
    sm.sm_type,
    CONCAT(cp.cp_department, '-', cp.cp_type) AS dept_type,
    COUNT(DISTINCT cs.cs_order_number) AS order_cnt,
    SUM(cs.cs_net_paid) AS total_net_paid,
    ROW_NUMBER() OVER (PARTITION BY p.p_promo_id ORDER BY SUM(cs.cs_net_paid) DESC) AS promo_rank
FROM catalog_sales cs
JOIN date_dim d
  ON cs.cs_sold_date_sk = d.d_date_sk
JOIN promotion p
  ON cs.cs_promo_sk = p.p_promo_sk
JOIN ship_mode sm
  ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN catalog_page cp
  ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
WHERE d.d_year = 2002
  AND regexp_like(p.p_promo_name, '\\d{4}')
  AND cp.cp_description LIKE 'Elect%'
GROUP BY
    p.p_promo_id,
    p.p_promo_name,
    regexp_extract(p.p_promo_name, '(\\d{4})', 1),
    sm.sm_type,
    cp.cp_department,
    cp.cp_type
ORDER BY total_net_paid DESC
LIMIT 100
