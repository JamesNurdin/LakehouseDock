SELECT
    s.s_store_id,
    d.d_year,
    cd.cd_gender,
    hd.hd_buy_potential,
    i.i_category,
    sum(ss.ss_net_paid) AS net_paid,
    sum(ss.ss_net_profit) AS net_profit,
    count(DISTINCT ss.ss_ticket_number) AS orders
FROM store_sales ss
JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
JOIN store s ON ss.ss_store_sk = s.s_store_sk
JOIN item i ON ss.ss_item_sk = i.i_item_sk
JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
LEFT JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
WHERE d.d_year = 2002
  AND s.s_state = 'CA'
GROUP BY
    s.s_store_id,
    d.d_year,
    cd.cd_gender,
    hd.hd_buy_potential,
    i.i_category
ORDER BY net_paid DESC
LIMIT 100
