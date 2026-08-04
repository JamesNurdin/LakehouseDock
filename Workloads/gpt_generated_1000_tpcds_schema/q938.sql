WITH
catalog_promos AS (
   SELECT
       p.p_promo_sk,
       p.p_promo_name,
       p.p_channel_demo,
       COUNT(*) AS cat_sales_cnt,
       SUM(cs.cs_net_paid) AS cat_total_paid
   FROM promotion p
   JOIN catalog_sales cs ON cs.cs_promo_sk = p.p_promo_sk
   JOIN date_dim d ON p.p_start_date_sk = d.d_date_sk
   WHERE d.d_year = 2001
   GROUP BY p.p_promo_sk, p.p_promo_name, p.p_channel_demo
),
web_promos AS (
   SELECT
       p.p_promo_sk,
       p.p_promo_name,
       p.p_channel_demo,
       COUNT(*) AS web_sales_cnt,
       SUM(ws.ws_net_paid) AS web_total_paid
   FROM promotion p
   JOIN web_sales ws ON ws.ws_promo_sk = p.p_promo_sk
   JOIN date_dim d ON p.p_start_date_sk = d.d_date_sk
   WHERE d.d_year = 2001
   GROUP BY p.p_promo_sk, p.p_promo_name, p.p_channel_demo
),
promo_diff AS (
   SELECT p_promo_sk FROM catalog_promos
   EXCEPT
   SELECT p_promo_sk FROM web_promos
)

SELECT
    p.p_promo_id,
    p.p_promo_name,
    CONCAT(p.p_promo_name, '_', p.p_channel_demo) AS promo_label,
    SUBSTRING(p.p_promo_name, 1, 5) AS promo_prefix,
    CASE
        WHEN regexp_like(p.p_promo_name, '^[A-Z]{3}') THEN 'ThreeUpper'
        ELSE 'Other'
    END AS name_pattern,
    (SELECT SUM(cs.cs_net_paid)
       FROM catalog_sales cs
       WHERE cs.cs_promo_sk = p.p_promo_sk) AS total_paid,
    cp.cat_sales_cnt,
    cp.cat_total_paid
FROM promotion p
JOIN catalog_promos cp ON cp.p_promo_sk = p.p_promo_sk
WHERE p.p_channel_demo = 'N'
  AND p.p_promo_name LIKE '%Sale%'
  AND p.p_promo_sk IN (SELECT p_promo_sk FROM promo_diff)

UNION DISTINCT

SELECT
    p.p_promo_id,
    p.p_promo_name,
    CONCAT(p.p_promo_name, '_', p.p_channel_demo) AS promo_label,
    SUBSTRING(p.p_promo_name, 1, 5) AS promo_prefix,
    CASE
        WHEN regexp_like(p.p_promo_name, '^[A-Z]{3}') THEN 'ThreeUpper'
        ELSE 'Other'
    END AS name_pattern,
    (SELECT SUM(ws.ws_net_paid)
       FROM web_sales ws
       WHERE ws.ws_promo_sk = p.p_promo_sk) AS total_paid,
    wp.web_sales_cnt,
    wp.web_total_paid
FROM promotion p
JOIN web_promos wp ON wp.p_promo_sk = p.p_promo_sk
WHERE p.p_channel_demo = 'N'
  AND p.p_promo_name LIKE '%Sale%'
  AND p.p_promo_sk IN (SELECT p_promo_sk FROM promo_diff)

ORDER BY total_paid DESC
LIMIT 100
