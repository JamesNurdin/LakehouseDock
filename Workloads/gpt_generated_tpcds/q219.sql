SELECT
    s.s_state,
    s.s_city,
    s.s_store_name,
    hd.hd_vehicle_count,
    CASE
        WHEN p.p_channel_email = 'Y' THEN 'Email'
        WHEN p.p_channel_tv = 'Y' THEN 'TV'
        ELSE 'Other'
    END AS promo_channel,
    sum(ss.ss_net_profit) AS total_net_profit,
    avg(ss.ss_ext_discount_amt) AS avg_discount_amount,
    count(*) AS transaction_count
FROM store_sales ss
JOIN store s
  ON ss.ss_store_sk = s.s_store_sk
JOIN household_demographics hd
  ON ss.ss_hdemo_sk = hd.hd_demo_sk
JOIN promotion p
  ON ss.ss_promo_sk = p.p_promo_sk
WHERE p.p_discount_active = 'Y'
  AND hd.hd_buy_potential = 'HIGH'
  AND s.s_state IN ('CA', 'TX', 'NY')
GROUP BY
    s.s_state,
    s.s_city,
    s.s_store_name,
    hd.hd_vehicle_count,
    CASE
        WHEN p.p_channel_email = 'Y' THEN 'Email'
        WHEN p.p_channel_tv = 'Y' THEN 'TV'
        ELSE 'Other'
    END
HAVING sum(ss.ss_net_profit) > 5000
ORDER BY total_net_profit DESC
LIMIT 20
