SELECT
    s.s_store_id,
    d_sold.d_year,
    d_sold.d_month_seq,
    p.p_promo_name,
    p.p_channel_tv,
    SUM(ss.ss_net_profit) AS total_net_profit,
    SUM(ss.ss_ext_discount_amt) AS total_discount_amount,
    COUNT(*) AS transaction_count,
    AVG(wp.wp_image_count) AS avg_image_count,
    MAX(d_store_closed.d_date) AS store_closed_date,
    MIN(d_promo_start.d_date) AS promo_start_date,
    MAX(d_promo_end.d_date) AS promo_end_date
FROM store_sales ss
JOIN date_dim d_sold
    ON ss.ss_sold_date_sk = d_sold.d_date_sk
JOIN store s
    ON ss.ss_store_sk = s.s_store_sk
JOIN promotion p
    ON ss.ss_promo_sk = p.p_promo_sk
JOIN date_dim d_store_closed
    ON s.s_closed_date_sk = d_store_closed.d_date_sk
JOIN date_dim d_promo_start
    ON p.p_start_date_sk = d_promo_start.d_date_sk
JOIN date_dim d_promo_end
    ON p.p_end_date_sk = d_promo_end.d_date_sk
JOIN web_page wp
    ON wp.wp_creation_date_sk = d_sold.d_date_sk
WHERE d_sold.d_year = 2022
  AND s.s_state = 'CA'
  AND p.p_discount_active = 'Y'
GROUP BY
    s.s_store_id,
    d_sold.d_year,
    d_sold.d_month_seq,
    p.p_promo_name,
    p.p_channel_tv
HAVING SUM(ss.ss_net_profit) > 1000
ORDER BY total_net_profit DESC
LIMIT 100
