SELECT
    s.s_state,
    s.s_city,
    d_return.d_year AS return_year,
    p.p_promo_id,
    p.p_channel_tv,
    CONCAT(cd.cd_gender, '-', cd.cd_marital_status) AS gender_marital,
    CASE 
        WHEN cd.cd_credit_rating = 'A' THEN 'High'
        WHEN cd.cd_credit_rating = 'B' THEN 'Medium'
        ELSE 'Low'
    END AS credit_rating_group,
    (cd.cd_dep_employed_count + cd.cd_dep_college_count) AS total_deps,
    COUNT(*) AS num_returns,
    SUM(sr.sr_net_loss) AS total_net_loss,
    AVG(sr.sr_return_amt) AS avg_return_amount,
    SUM(sr.sr_return_quantity) AS total_return_qty,
    SUM(p.p_cost) AS total_promo_cost,
    AVG(CASE WHEN sr.sr_return_quantity > 1 THEN sr.sr_net_loss END) AS avg_multi_qty_loss,
    MAX(d_promo_start.d_date) AS promo_start_date,
    MIN(d_promo_end.d_date) AS promo_end_date
FROM store_returns sr
JOIN customer_demographics cd
    ON sr.sr_cdemo_sk = cd.cd_demo_sk
JOIN store s
    ON sr.sr_store_sk = s.s_store_sk
JOIN date_dim d_return
    ON sr.sr_returned_date_sk = d_return.d_date_sk
JOIN date_dim d_store_close
    ON s.s_closed_date_sk = d_store_close.d_date_sk
CROSS JOIN promotion p
JOIN date_dim d_promo_start
    ON p.p_start_date_sk = d_promo_start.d_date_sk
JOIN date_dim d_promo_end
    ON p.p_end_date_sk = d_promo_end.d_date_sk
WHERE d_return.d_date BETWEEN d_promo_start.d_date AND d_promo_end.d_date
  AND d_store_close.d_date >= d_return.d_date
GROUP BY 
    s.s_state,
    s.s_city,
    d_return.d_year,
    p.p_promo_id,
    p.p_channel_tv,
    CONCAT(cd.cd_gender, '-', cd.cd_marital_status),
    CASE 
        WHEN cd.cd_credit_rating = 'A' THEN 'High'
        WHEN cd.cd_credit_rating = 'B' THEN 'Medium'
        ELSE 'Low'
    END,
    (cd.cd_dep_employed_count + cd.cd_dep_college_count)
HAVING SUM(sr.sr_net_loss) > 1000
ORDER BY total_net_loss DESC
LIMIT 100
