SELECT
    s.s_store_name,
    p.p_promo_name,
    td.t_hour,
    cd.cd_gender,
    sum(ss.ss_ext_sales_price) AS total_sales,
    sum(ss.ss_ext_discount_amt) AS total_discount,
    sum(ss.ss_net_profit) AS total_sales_profit,
    coalesce(sum(sr.sr_return_amt), 0) AS total_returns,
    coalesce(sum(sr.sr_net_loss), 0) AS total_return_loss,
    sum(ss.ss_net_profit) - coalesce(sum(sr.sr_net_loss), 0) AS net_profit_after_returns,
    sum(ss.ss_ext_sales_price) - coalesce(sum(sr.sr_return_amt), 0) AS net_sales
FROM store_sales ss
JOIN store s
    ON ss.ss_store_sk = s.s_store_sk
JOIN promotion p
    ON ss.ss_promo_sk = p.p_promo_sk
JOIN time_dim td
    ON ss.ss_sold_time_sk = td.t_time_sk
JOIN customer c
    ON ss.ss_customer_sk = c.c_customer_sk
JOIN customer_demographics cd
    ON ss.ss_cdemo_sk = cd.cd_demo_sk
LEFT JOIN store_returns sr
    ON sr.sr_ticket_number = ss.ss_ticket_number
    AND sr.sr_item_sk = ss.ss_item_sk
GROUP BY s.s_store_name, p.p_promo_name, td.t_hour, cd.cd_gender
ORDER BY s.s_store_name, p.p_promo_name, td.t_hour, cd.cd_gender
