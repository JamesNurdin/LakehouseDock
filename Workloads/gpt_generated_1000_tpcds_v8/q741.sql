/*
Goal: Identify active customers (born 1960‑1970) who viewed promotional web pages, summarizing the number of distinct pages, total promotion cost and average character count per customer‑promotion pair. The query demonstrates complex joins, multiple filters, grouping, HAVING, window ranking, a scalar subquery, a set‑operation (EXCEPT) to filter customers, and pagination.
*/
WITH high_ad_customers AS (
    SELECT DISTINCT wp_customer_sk
    FROM web_page
    WHERE wp_max_ad_count >= 3
),
landing_customers AS (
    SELECT DISTINCT wp_customer_sk
    FROM web_page
    WHERE wp_type = 'Landing'
),
target_customers AS (
    SELECT wp_customer_sk
    FROM high_ad_customers
    EXCEPT
    SELECT wp_customer_sk
    FROM landing_customers
),
promo_dates AS (
    SELECT p.p_promo_sk,
           p.p_promo_name,
           p.p_cost,
           p.p_discount_active,
           p.p_channel_demo,
           d_start.d_year AS start_year,
           d_end.d_year   AS end_year,
           d_start.d_date AS start_date,
           d_end.d_date   AS end_date
    FROM promotion p
    JOIN date_dim d_start ON p.p_start_date_sk = d_start.d_date_sk
    JOIN date_dim d_end   ON p.p_end_date_sk   = d_end.d_date_sk
    WHERE p.p_discount_active = 'N'
      AND p.p_channel_demo   = 'N'
      AND p.p_end_date_sk   BETWEEN 2450300 AND 2450400
),
page_info AS (
    SELECT wp.wp_web_page_id,
           wp.wp_customer_sk,
           wp.wp_max_ad_count,
           wp.wp_type,
           wp.wp_char_count,
           d_creation.d_year AS creation_year,
           d_access.d_year   AS access_year
    FROM web_page wp
    JOIN date_dim d_creation ON wp.wp_creation_date_sk = d_creation.d_date_sk
    JOIN date_dim d_access   ON wp.wp_access_date_sk   = d_access.d_date_sk
    WHERE wp.wp_max_ad_count >= 2
      AND wp.wp_type = 'Content'
),
customer_info AS (
    SELECT c.c_customer_sk,
           c.c_customer_id,
           c.c_last_name,
           c.c_birth_year,
           d_birth.d_year AS birth_year
    FROM customer c
    JOIN date_dim d_birth ON c.c_first_shipto_date_sk = d_birth.d_date_sk
    WHERE c.c_birth_year BETWEEN 1960 AND 1970
),
promo_page AS (
    SELECT pi.wp_web_page_id,
           pi.wp_customer_sk,
           pd.p_promo_sk,
           pd.p_promo_name,
           pd.p_cost,
           pi.wp_char_count
    FROM page_info pi
    JOIN promo_dates pd ON pi.creation_year = pd.start_year
    WHERE pi.creation_year = pd.start_year
)
SELECT
    ci.c_customer_id,
    ci.c_last_name,
    pp.p_promo_name,
    COUNT(DISTINCT pp.wp_web_page_id)                     AS page_cnt,
    SUM(pp.p_cost)                                        AS total_promo_cost,
    AVG(pp.wp_char_count)                                 AS avg_char_count,
    (SELECT MAX(p_cost) FROM promotion)                  AS overall_max_promo_cost,
    ROW_NUMBER() OVER (ORDER BY SUM(pp.p_cost) DESC)     AS rn,
    RANK() OVER (PARTITION BY pp.p_promo_name ORDER BY AVG(pp.wp_char_count) DESC) AS char_rank
FROM promo_page pp
JOIN customer_info ci ON pp.wp_customer_sk = ci.c_customer_sk
WHERE ci.c_customer_sk IN (SELECT wp_customer_sk FROM target_customers)
  AND EXISTS (
        SELECT 1
        FROM promotion p2
        WHERE p2.p_promo_sk = pp.p_promo_sk
          AND p2.p_cost > (SELECT MAX(p_cost) FROM promotion)
    )
GROUP BY ci.c_customer_id, ci.c_last_name, pp.p_promo_name
HAVING COUNT(DISTINCT pp.wp_web_page_id) > 3
   AND SUM(pp.p_cost) > 1000
ORDER BY total_promo_cost DESC
OFFSET 0 ROWS FETCH NEXT 20 ROWS ONLY
