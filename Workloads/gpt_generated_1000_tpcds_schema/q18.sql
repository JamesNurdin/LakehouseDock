/*
Goal: Identify the most expensive active promotions linked to web pages created on open web‑site dates, rank them per site, classify promotion cost relative to the overall average, and filter on several business attributes.
*/
WITH sampled_web_page AS (
    SELECT
        wp_web_page_sk,
        wp_web_page_id,
        wp_creation_date_sk,
        wp_url,
        wp_autogen_flag,
        wp_max_ad_count
    FROM web_page
    TABLESAMPLE BERNOULLI (10)
),
joined_data AS (
    SELECT
        d.d_date,
        d.d_year,
        d.d_month_seq,
        d.d_dow,
        p.p_promo_id,
        p.p_promo_name,
        p.p_cost,
        p.p_channel_email,
        p.p_channel_demo,
        wp.wp_web_page_id,
        wp.wp_url,
        wp.wp_autogen_flag,
        wp.wp_max_ad_count,
        ws.web_site_id,
        ws.web_name,
        ws.web_manager
    FROM date_dim d
    LEFT JOIN promotion p
        ON p.p_start_date_sk = d.d_date_sk
    LEFT JOIN sampled_web_page wp
        ON wp.wp_creation_date_sk = d.d_date_sk
    LEFT JOIN web_site ws
        ON ws.web_open_date_sk = d.d_date_sk
    WHERE d.d_dow BETWEEN 1 AND 5                                  -- weekday filter
      AND d.d_current_day = 'N'                                      -- not current day flag
      AND d.d_following_holiday = 'N'                                 -- not a holiday follower
      AND p.p_channel_email = 'N'                                     -- email channel inactive
      AND p.p_channel_demo = 'N'                                      -- demo channel inactive
      AND wp.wp_autogen_flag = 'Y'                                    -- only auto‑generated pages
      AND wp.wp_max_ad_count >= 2                                    -- at least two ad slots
      AND ws.web_manager IN ('Charles Parker', 'Harold Wilson')      -- specific managers
)
SELECT
    d_year,
    d_month_seq,
    web_site_id,
    web_name,
    p_promo_id,
    p_promo_name,
    p_cost,
    wp_web_page_id,
    wp_url,
    wp_max_ad_count,
    RANK() OVER (PARTITION BY web_site_id ORDER BY p_cost DESC) AS promo_cost_rank,
    CASE
        WHEN p_cost > (SELECT AVG(p_cost) FROM promotion WHERE p_channel_email = 'N') THEN 'High'
        ELSE 'Low'
    END AS cost_category
FROM joined_data
ORDER BY d_year DESC, d_month_seq DESC, promo_cost_rank ASC
LIMIT 100
