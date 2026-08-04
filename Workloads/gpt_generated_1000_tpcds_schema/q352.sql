WITH promo_agg AS (
    SELECT
        p_start_date_sk,
        COUNT(DISTINCT p_promo_id) AS cnt_distinct_promo,
        SUM(p_cost) AS total_promo_cost
    FROM promotion
    WHERE p_response_target = 1
      AND p_channel_demo = 'N'
    GROUP BY p_start_date_sk
),
store_excluded AS (
    SELECT s_store_id
    FROM store
    WHERE s_state = 'CA'
    EXCEPT
    SELECT s_store_id
    FROM store
    WHERE s_city = 'Los Angeles'
)
SELECT
    d.d_year,
    s.s_store_name,
    p.cnt_distinct_promo,
    p.total_promo_cost,
    COUNT(DISTINCT c.cc_call_center_id) AS distinct_call_centers,
    COUNT(DISTINCT wp.wp_customer_sk) AS distinct_customers,
    CASE
        WHEN s.s_tax_percentage > 5 THEN 'High_Tax'
        ELSE 'Low_Tax'
    END AS tax_category
FROM date_dim d
JOIN promo_agg p ON p.p_start_date_sk = d.d_date_sk
JOIN call_center c ON c.cc_closed_date_sk = d.d_date_sk
JOIN store s ON s.s_closed_date_sk = d.d_date_sk
JOIN web_page wp ON wp.wp_creation_date_sk = d.d_date_sk
WHERE d.d_year = 2000
  AND d.d_following_holiday = 'N'
  AND s.s_store_id IN (SELECT s_store_id FROM store_excluded)
  AND c.cc_market_manager = 'Kevin Damico'
GROUP BY
    d.d_year,
    s.s_store_name,
    p.cnt_distinct_promo,
    p.total_promo_cost,
    s.s_tax_percentage
ORDER BY p.total_promo_cost DESC
LIMIT 100
