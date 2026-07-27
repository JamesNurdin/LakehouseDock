WITH base_sales AS (
   SELECT
       cs.cs_sold_date_sk,
       cs.cs_net_paid,
       cs.cs_catalog_page_sk,
       cs.cs_ship_mode_sk,
       cs.cs_promo_sk,
       d.d_date,
       d.d_year,
       cp.cp_catalog_page_id,
       sm.sm_ship_mode_id
   FROM catalog_sales cs
   JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
   JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
   JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
   LEFT JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
),
promo_sales AS (
   SELECT DISTINCT
       cp_catalog_page_id,
       d_date,
       cs_net_paid,
       sm_ship_mode_id
   FROM base_sales
   WHERE cs_promo_sk IS NOT NULL
     AND d_year = 2001
),
nonpromo_sales AS (
   SELECT DISTINCT
       cp_catalog_page_id,
       d_date,
       cs_net_paid,
       sm_ship_mode_id
   FROM base_sales
   WHERE cs_promo_sk IS NULL
     AND d_year = 2001
),
combined AS (
   SELECT * FROM promo_sales
   UNION ALL
   SELECT * FROM nonpromo_sales
)
SELECT
   cp_catalog_page_id,
   d_date,
   sm_ship_mode_id,
   SUM(cs_net_paid) OVER (PARTITION BY cp_catalog_page_id) AS total_net_paid,
   ROW_NUMBER() OVER (PARTITION BY cp_catalog_page_id ORDER BY d_date DESC) AS rn
FROM combined
ORDER BY total_net_paid DESC, d_date ASC
LIMIT 100
