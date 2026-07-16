SELECT
    cc.cc_division_name,
    s.s_state,
    d.d_year,
    CASE
        WHEN cc.cc_employees >= 200 THEN 'Large'
        WHEN cc.cc_employees >= 100 THEN 'Medium'
        ELSE 'Small'
    END AS center_size,
    SUM(p.p_cost) AS total_promo_cost,
    COUNT(DISTINCT wp.wp_web_page_id) AS distinct_pages,
    AVG(cc.cc_tax_percentage) AS avg_tax_pct,
    SUM(s.s_floor_space) AS total_floor_space,
    COUNT(*) AS record_cnt
FROM call_center cc
JOIN date_dim d
    ON cc.cc_closed_date_sk = d.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = d.d_date_sk
JOIN promotion p
    ON p.p_start_date_sk = d.d_date_sk
JOIN web_page wp
    ON wp.wp_creation_date_sk = d.d_date_sk
WHERE p.p_discount_active = 'Y'
  AND cc.cc_employees > 0
  AND wp.wp_autogen_flag = 'N'
GROUP BY
    cc.cc_division_name,
    s.s_state,
    d.d_year,
    CASE
        WHEN cc.cc_employees >= 200 THEN 'Large'
        WHEN cc.cc_employees >= 100 THEN 'Medium'
        ELSE 'Small'
    END
HAVING SUM(p.p_cost) > 1000
ORDER BY total_promo_cost DESC
LIMIT 100
