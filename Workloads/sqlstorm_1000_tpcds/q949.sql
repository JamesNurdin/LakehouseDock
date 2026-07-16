SELECT
    s.s_store_name,
    d.d_year,
    d.d_month_seq,
    i.i_brand,
    cd.cd_gender,
    SUM(ss.ss_net_profit) AS total_net_profit,
    SUM(ss.ss_net_paid) AS total_net_paid,
    COUNT(DISTINCT ss.ss_ticket_number) AS total_transactions
FROM store_sales ss
JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
JOIN store s ON ss.ss_store_sk = s.s_store_sk
JOIN item i ON ss.ss_item_sk = i.i_item_sk
JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
LEFT JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
WHERE d.d_year = 2001
  AND s.s_state = 'CA'
  AND i.i_brand = 'Brand#12'
  AND cd.cd_gender = 'M'
  AND (p.p_discount_active = 'Y' OR p.p_promo_sk IS NULL)
GROUP BY
    s.s_store_name,
    d.d_year,
    d.d_month_seq,
    i.i_brand,
    cd.cd_gender
ORDER BY total_net_profit DESC
LIMIT 100
