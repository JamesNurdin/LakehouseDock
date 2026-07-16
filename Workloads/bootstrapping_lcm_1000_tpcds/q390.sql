SELECT
    s.s_store_id,
    s.s_city,
    s.s_state,
    cd.cd_gender,
    cd.cd_education_status,
    CASE
        WHEN cd.cd_marital_status = 'M' THEN 'Married'
        WHEN cd.cd_marital_status = 'S' THEN 'Single'
        ELSE 'Other'
    END AS marital_category,
    EXTRACT(year FROM d_ret.d_date) AS return_year,
    EXTRACT(month FROM d_ret.d_date) AS return_month,
    COUNT(DISTINCT sr.sr_ticket_number) AS num_returns,
    SUM(sr.sr_return_amt) AS total_return_amount,
    SUM(sr.sr_net_loss) AS total_net_loss,
    SUM(sr.sr_return_amt_inc_tax) AS total_return_amount_inc_tax,
    AVG(sr.sr_return_quantity) AS avg_return_quantity,
    COUNT(DISTINCT p.p_promo_id) AS num_promotions,
    SUM(CASE WHEN p.p_discount_active = 'Y' THEN sr.sr_return_amt ELSE 0 END) AS promo_discounted_return_amount,
    SUM(CASE WHEN p.p_channel_tv = 'Y' THEN sr.sr_return_amt ELSE 0 END) AS tv_channel_return_amount,
    SUM(CASE WHEN d_closed.d_date < d_ret.d_date THEN 1 ELSE 0 END) AS returns_after_store_closed,
    ROUND(SUM(sr.sr_return_amt) / NULLIF(COUNT(DISTINCT sr.sr_ticket_number), 0), 2) AS avg_return_amount_per_ticket
FROM store_returns sr
JOIN date_dim d_ret
    ON sr.sr_returned_date_sk = d_ret.d_date_sk
JOIN customer_demographics cd
    ON sr.sr_cdemo_sk = cd.cd_demo_sk
JOIN store s
    ON sr.sr_store_sk = s.s_store_sk
JOIN date_dim d_closed
    ON s.s_closed_date_sk = d_closed.d_date_sk
JOIN promotion p
    ON TRUE
JOIN date_dim d_start
    ON p.p_start_date_sk = d_start.d_date_sk
JOIN date_dim d_end
    ON p.p_end_date_sk = d_end.d_date_sk
WHERE d_ret.d_date BETWEEN d_start.d_date AND d_end.d_date
GROUP BY
    s.s_store_id,
    s.s_city,
    s.s_state,
    cd.cd_gender,
    cd.cd_education_status,
    CASE
        WHEN cd.cd_marital_status = 'M' THEN 'Married'
        WHEN cd.cd_marital_status = 'S' THEN 'Single'
        ELSE 'Other'
    END,
    EXTRACT(year FROM d_ret.d_date),
    EXTRACT(month FROM d_ret.d_date)
ORDER BY s.s_store_id, return_year, return_month
