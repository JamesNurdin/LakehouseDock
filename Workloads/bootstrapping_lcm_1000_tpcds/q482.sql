SELECT
    s.s_store_id,
    s.s_store_name,
    d_ret.d_year,
    d_ret.d_quarter_name,
    p.p_promo_name,
    COALESCE(p.p_channel_tv, p.p_channel_email, p.p_channel_catalog, p.p_channel_radio) AS primary_channel,
    COUNT(*) AS num_returns,
    SUM(cr.cr_return_amount) AS total_return_amount,
    SUM(cr.cr_net_loss) AS total_net_loss,
    AVG(cr.cr_return_quantity) AS avg_return_qty,
    SUM(cr.cr_fee) AS total_fee,
    date_diff('day', d_start.d_date, d_end.d_date) AS promo_duration_days,
    CASE
        WHEN SUM(cr.cr_net_loss) > 5000 THEN 'HIGH'
        WHEN SUM(cr.cr_net_loss) > 2000 THEN 'MEDIUM'
        ELSE 'LOW'
    END AS loss_category
FROM catalog_returns cr
JOIN date_dim d_ret
    ON cr.cr_returned_date_sk = d_ret.d_date_sk
CROSS JOIN promotion p
JOIN date_dim d_start
    ON p.p_start_date_sk = d_start.d_date_sk
JOIN date_dim d_end
    ON p.p_end_date_sk = d_end.d_date_sk
CROSS JOIN date_dim d_store
JOIN store s
    ON s.s_closed_date_sk = d_store.d_date_sk
WHERE
    d_ret.d_date BETWEEN d_start.d_date AND d_end.d_date
    AND d_ret.d_year BETWEEN 2015 AND 2020
    AND p.p_discount_active = 'Y'
    AND cr.cr_return_quantity > 0
GROUP BY
    s.s_store_id,
    s.s_store_name,
    d_ret.d_year,
    d_ret.d_quarter_name,
    p.p_promo_name,
    COALESCE(p.p_channel_tv, p.p_channel_email, p.p_channel_catalog, p.p_channel_radio),
    date_diff('day', d_start.d_date, d_end.d_date)
HAVING
    SUM(cr.cr_net_loss) > 0
ORDER BY
    total_net_loss DESC
LIMIT 100
