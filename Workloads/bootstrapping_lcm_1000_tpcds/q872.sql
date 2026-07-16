WITH promo_dates AS (
   SELECT
       p.p_promo_id,
       p.p_item_sk,
       p.p_cost,
       p.p_response_target,
       p.p_start_date_sk,
       p.p_end_date_sk,
       d_start.d_year AS start_year,
       d_start.d_month_seq AS start_month_seq,
       d_start.d_date AS start_date,
       d_end.d_year AS end_year,
       d_end.d_month_seq AS end_month_seq,
       d_end.d_date AS end_date
   FROM promotion p
   JOIN date_dim d_start
     ON p.p_start_date_sk = d_start.d_date_sk
   JOIN date_dim d_end
     ON p.p_end_date_sk = d_end.d_date_sk
),
store_info AS (
   SELECT
       s.s_store_sk,
       s.s_store_name,
       s.s_city,
       s.s_state,
       s.s_market_id,
       s.s_division_name,
       s.s_closed_date_sk,
       s.s_number_employees,
       d_closure.d_year AS closure_year,
       d_closure.d_month_seq AS closure_month_seq
   FROM store s
   JOIN date_dim d_closure
     ON s.s_closed_date_sk = d_closure.d_date_sk
),
web_page_stats AS (
   SELECT
       wp.wp_web_page_id,
       wp.wp_customer_sk,
       wp.wp_type,
       wp.wp_image_count,
       wp.wp_link_count,
       wp.wp_char_count,
       wp.wp_creation_date_sk,
       wp.wp_access_date_sk,
       d_create.d_year AS creation_year,
       d_create.d_month_seq AS creation_month_seq,
       d_access.d_year AS access_year,
       d_access.d_month_seq AS access_month_seq,
       CASE
           WHEN wp.wp_image_count > 0 THEN wp.wp_image_count * 1.0 / NULLIF(wp.wp_link_count, 0)
           ELSE NULL
       END AS img_to_link_ratio
   FROM web_page wp
   JOIN date_dim d_create
     ON wp.wp_creation_date_sk = d_create.d_date_sk
   JOIN date_dim d_access
     ON wp.wp_access_date_sk = d_access.d_date_sk
)

SELECT
    pd.start_year,
    pd.start_month_seq,
    CASE
        WHEN i.i_category = 'Books' THEN 'Books'
        WHEN i.i_category = 'Electronics' THEN 'Electronics'
        ELSE 'Other'
    END AS category_group,
    i.i_brand,
    s.s_division_name,
    SUM(pd.p_cost) AS total_promo_cost,
    AVG(i.i_current_price) AS avg_item_price,
    COUNT(DISTINCT wp.wp_web_page_id) AS distinct_web_pages,
    SUM(wp.wp_image_count) FILTER (WHERE wp.wp_type = 'Home') AS total_home_images,
    SUM(wp.wp_image_count) FILTER (WHERE wp.wp_type <> 'Home') AS total_other_images,
    SUM(wp.wp_link_count) AS total_links,
    AVG(wp.img_to_link_ratio) AS avg_img_to_link_ratio,
    COUNT(DISTINCT s.s_store_sk) AS stores_involved,
    SUM(pd.p_cost) / NULLIF(s.s_number_employees, 0) AS promo_cost_per_employee,
    ROW_NUMBER() OVER (PARTITION BY pd.start_year, pd.start_month_seq ORDER BY SUM(pd.p_cost) DESC) AS promo_cost_rank
FROM promo_dates pd
JOIN item i
  ON pd.p_item_sk = i.i_item_sk
JOIN store_info s
  ON s.s_closed_date_sk BETWEEN pd.p_start_date_sk AND pd.p_end_date_sk
JOIN web_page_stats wp
  ON wp.wp_creation_date_sk BETWEEN pd.p_start_date_sk AND pd.p_end_date_sk
WHERE i.i_current_price > 0
  AND pd.p_cost > 0
GROUP BY
    pd.start_year,
    pd.start_month_seq,
    CASE
        WHEN i.i_category = 'Books' THEN 'Books'
        WHEN i.i_category = 'Electronics' THEN 'Electronics'
        ELSE 'Other'
    END,
    i.i_brand,
    s.s_division_name,
    s.s_number_employees
ORDER BY total_promo_cost DESC
LIMIT 100
