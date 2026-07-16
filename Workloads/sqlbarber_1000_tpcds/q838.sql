SELECT cd.cd_gender, t.t_hour, COUNT(*) AS sales_count, SUM(ss.ss_net_paid) AS total_net_paid
FROM store_sales ss
JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
JOIN (
    SELECT p_promo_sk, p_promo_name
    FROM promotion
    WHERE p_discount_active = 'N'
) p ON ss.ss_promo_sk = p.p_promo_sk
WHERE cd.cd_marital_status = 'U'
GROUP BY cd.cd_gender, t.t_hour
HAVING SUM(ss.ss_net_paid) > 3533.38
