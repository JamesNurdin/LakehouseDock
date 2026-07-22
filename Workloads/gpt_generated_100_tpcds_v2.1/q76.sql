WITH distinct_promos AS (
    SELECT DISTINCT p_start_date_sk, p_promo_id
    FROM promotion
)
SELECT
    ca.ca_state,
    ca.ca_city,
    cd.cd_gender,
    r.r_reason_desc,
    d_date.d_year,
    SUM(COALESCE(sr.sr_net_loss, 0) + COALESCE(wr.wr_net_loss, 0)) AS total_net_loss,
    AVG(COALESCE(sr.sr_net_loss, 0) + COALESCE(wr.wr_net_loss, 0)) AS avg_net_loss_per_return,
    COUNT(*) AS return_count
FROM store_returns sr
JOIN date_dim d_date
    ON sr.sr_returned_date_sk = d_date.d_date_sk
JOIN time_dim t
    ON sr.sr_return_time_sk = t.t_time_sk
JOIN customer_address ca
    ON sr.sr_addr_sk = ca.ca_address_sk
JOIN customer_demographics cd
    ON sr.sr_cdemo_sk = cd.cd_demo_sk
JOIN household_demographics hd
    ON sr.sr_hdemo_sk = hd.hd_demo_sk
JOIN income_band ib
    ON hd.hd_income_band_sk = ib.ib_income_band_sk
JOIN reason r
    ON sr.sr_reason_sk = r.r_reason_sk
LEFT JOIN web_returns wr
    ON wr.wr_returned_date_sk = d_date.d_date_sk
    AND wr.wr_returned_time_sk = t.t_time_sk
LEFT JOIN web_page wp
    ON wr.wr_web_page_sk = wp.wp_web_page_sk
LEFT JOIN distinct_promos dp
    ON dp.p_start_date_sk = d_date.d_date_sk
LEFT JOIN promotion p
    ON p.p_start_date_sk = d_date.d_date_sk
WHERE
    ca.ca_state = 'TX'
    AND ca.ca_city = 'Fairfield'
    AND t.t_hour BETWEEN 9 AND 17
    AND d_date.d_year = 2001
    AND ib.ib_lower_bound >= 50000
    AND p.p_discount_active = 'Y'
    AND r.r_reason_desc = 'Damaged'
    AND (
        SELECT COUNT(DISTINCT p2.p_promo_id)
        FROM promotion p2
        WHERE p2.p_start_date_sk = d_date.d_date_sk
    ) > 1
GROUP BY
    ca.ca_state,
    ca.ca_city,
    cd.cd_gender,
    r.r_reason_desc,
    d_date.d_year
ORDER BY total_net_loss DESC
LIMIT 100
