SELECT
    s.s_city,
    s.s_state,
    cd.cd_gender,
    i.i_category,
    hd.hd_buy_potential,
    d.d_year,
    SUM(ss.ss_net_paid) AS total_net_paid,
    SUM(ss.ss_net_profit) AS total_net_profit,
    AVG(ss.ss_ext_discount_amt) AS avg_discount,
    COUNT(*) AS sales_count
FROM store_sales ss
JOIN store s ON ss.ss_store_sk = s.s_store_sk
JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
JOIN item i ON ss.ss_item_sk = i.i_item_sk
WHERE d.d_year BETWEEN 1999 AND 2001
  AND s.s_state = 'CA'
  AND cd.cd_gender = 'M'
GROUP BY s.s_city, s.s_state, cd.cd_gender, i.i_category, hd.hd_buy_potential, d.d_year
HAVING SUM(ss.ss_net_paid) > 10000
ORDER BY total_net_paid DESC
LIMIT 50
