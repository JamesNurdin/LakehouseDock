/*
Goal: Identify top promotional campaigns linked to web pages by total sales, filtering for active promotions, recent web pages, and high‑value sales, and show per‑promotion sales count.
*/
WITH sales_agg AS (
    SELECT
        ws_promo_sk,
        ws_web_page_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        SUM(ws_quantity) AS total_qty,
        COUNT(*) AS sales_cnt
    FROM web_sales
    WHERE ws_coupon_amt > 100
      AND ws_ext_list_price > 5000
      AND ws_sold_date_sk BETWEEN 2450000 AND 2455000
    GROUP BY ws_promo_sk, ws_web_page_sk
),
promo_filter AS (
    SELECT p_promo_sk
    FROM promotion
    WHERE p_discount_active = 'Y'
      AND p_response_target > 0
      AND p_purpose <> 'Unknown'
),
page_filter AS (
    SELECT wp_web_page_sk
    FROM web_page
    WHERE wp_rec_start_date >= DATE '1999-01-01'
      AND wp_autogen_flag = 'Y'
      AND wp_type = 'home'
),
intersect_keys AS (
    SELECT p_promo_sk AS key_sk FROM promo_filter
    INTERSECT
    SELECT ws_promo_sk FROM sales_agg
)
SELECT DISTINCT
    p.p_promo_id,
    wp.wp_url,
    sa.total_sales,
    sa.total_qty,
    (
        SELECT COUNT(*)
        FROM web_sales ws2
        WHERE ws2.ws_promo_sk = p.p_promo_sk
    ) AS promo_sales_count
FROM intersect_keys ik
JOIN promotion p           ON p.p_promo_sk = ik.key_sk
JOIN sales_agg sa          ON sa.ws_promo_sk = p.p_promo_sk
JOIN web_page wp           ON wp.wp_web_page_sk = sa.ws_web_page_sk
WHERE wp.wp_access_date_sk IN (2452611, 2452639, 2452596)
  AND p.p_cost > 1000
  AND wp.wp_max_ad_count >= 5
ORDER BY sa.total_sales DESC
LIMIT 100
