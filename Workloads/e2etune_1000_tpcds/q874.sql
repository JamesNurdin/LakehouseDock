SELECT s.s_store_name,
       p.p_promo_name,
       cd.cd_gender,
       hd.hd_buy_potential,
       SUM(ss.ss_net_paid) AS total_sales_net_paid,
       COALESCE(SUM(r.total_return_amount), 0) AS total_return_amount,
       SUM(ss.ss_net_profit) - COALESCE(SUM(r.total_return_amount), 0) AS net_profit_after_returns,
       COUNT(DISTINCT ss.ss_ticket_number) AS num_transactions,
       RANK() OVER (PARTITION BY p.p_promo_name ORDER BY (SUM(ss.ss_net_profit) - COALESCE(SUM(r.total_return_amount), 0)) DESC) AS store_rank_by_profit
FROM store_sales ss
JOIN store s ON ss.ss_store_sk = s.s_store_sk
JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
LEFT JOIN (
    SELECT cr_refunded_cdemo_sk AS cd_demo_sk,
           cr_refunded_hdemo_sk AS hd_demo_sk,
           cr_refunded_addr_sk AS ca_address_sk,
           SUM(cr_return_amount) AS total_return_amount
    FROM catalog_returns
    WHERE cr_return_amount > 0
    GROUP BY cr_refunded_cdemo_sk, cr_refunded_hdemo_sk, cr_refunded_addr_sk
) r
  ON cd.cd_demo_sk = r.cd_demo_sk
 AND hd.hd_demo_sk = r.hd_demo_sk
 AND ca.ca_address_sk = r.ca_address_sk
WHERE s.s_state = 'CA'
  AND cd.cd_credit_rating = 'A'
  AND hd.hd_buy_potential = 'HIGH'
  AND ss.ss_sold_date_sk BETWEEN 2451545 AND 2451910
GROUP BY s.s_store_name, p.p_promo_name, cd.cd_gender, hd.hd_buy_potential
ORDER BY net_profit_after_returns DESC
LIMIT 50
