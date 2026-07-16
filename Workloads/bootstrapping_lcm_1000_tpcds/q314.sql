SELECT
    COALESCE(s.s_store_id, 'ALL_STORES') AS store_id,
    COALESCE(hd.hd_buy_potential, 'ALL_POTENTIAL') AS buy_potential,
    CASE
        WHEN GROUPING(s.s_store_id) = 0 AND GROUPING(hd.hd_buy_potential) = 0 THEN 'DETAIL'
        WHEN GROUPING(s.s_store_id) = 0 AND GROUPING(hd.hd_buy_potential) = 1 THEN 'STORE_AGG'
        WHEN GROUPING(s.s_store_id) = 1 AND GROUPING(hd.hd_buy_potential) = 0 THEN 'POTENTIAL_AGG'
        ELSE 'GRAND_TOTAL'
    END AS grouping_level,
    d.d_year,
    MAX(d_closure.d_date) AS store_closed_date,
    SUM(sr.sr_net_loss) AS total_net_loss,
    COUNT(DISTINCT sr.sr_ticket_number) AS total_returns,
    AVG(sr.sr_return_quantity) AS avg_return_qty,
    SUM(COALESCE(wp.wp_image_count, 0)) AS total_image_count,
    SUM(COALESCE(wp.wp_link_count, 0)) AS total_link_count,
    SUM(COALESCE(wp.wp_char_count, 0)) AS total_char_count,
    COUNT(DISTINCT wp.wp_web_page_id) AS total_pages
FROM store_returns sr
JOIN date_dim d
    ON sr.sr_returned_date_sk = d.d_date_sk
JOIN household_demographics hd
    ON sr.sr_hdemo_sk = hd.hd_demo_sk
JOIN store s
    ON sr.sr_store_sk = s.s_store_sk
JOIN date_dim d_closure
    ON s.s_closed_date_sk = d_closure.d_date_sk
LEFT JOIN web_page wp
    ON wp.wp_creation_date_sk = d.d_date_sk
    OR wp.wp_access_date_sk = d.d_date_sk
WHERE d.d_year >= 2020
GROUP BY GROUPING SETS (
    (s.s_store_id, hd.hd_buy_potential, d.d_year),
    (s.s_store_id, d.d_year),
    (hd.hd_buy_potential, d.d_year),
    (d.d_year),
    ()
)
HAVING SUM(sr.sr_net_loss) IS NOT NULL
ORDER BY total_net_loss DESC
LIMIT 100
