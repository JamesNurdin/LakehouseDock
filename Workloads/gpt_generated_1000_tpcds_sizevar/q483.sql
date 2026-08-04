WITH cs_sample AS (
    SELECT cs_bill_customer_sk,
           cs_ship_customer_sk,
           cs_ship_mode_sk,
           cs_promo_sk,
           cs_order_number,
           cs_net_profit
    FROM catalog_sales
    TABLESAMPLE BERNOULLI (10)
)
SELECT promo1.p_promo_name,
       sm1.sm_type,
       r2.r_reason_desc,
       SUM(cs_sample.cs_net_profit) AS total_profit,
       SUM(sr1.sr_net_loss) AS total_loss,
       COUNT(DISTINCT cust_bill.c_customer_sk) AS bill_customer_cnt,
       COUNT(DISTINCT cust_ship.c_customer_sk) AS ship_customer_cnt
FROM cs_sample
JOIN customer AS cust_bill
  ON cs_sample.cs_bill_customer_sk = cust_bill.c_customer_sk
JOIN customer AS cust_ship
  ON cs_sample.cs_ship_customer_sk = cust_ship.c_customer_sk
JOIN ship_mode AS sm1
  ON cs_sample.cs_ship_mode_sk = sm1.sm_ship_mode_sk
JOIN promotion AS promo1
  ON cs_sample.cs_promo_sk = promo1.p_promo_sk
JOIN store_returns AS sr1
  ON sr1.sr_customer_sk = cust_bill.c_customer_sk
FULL OUTER JOIN reason AS r2
  ON sr1.sr_reason_sk = r2.r_reason_sk
JOIN reason AS r1
  ON sr1.sr_reason_sk = r1.r_reason_sk
JOIN promotion AS promo2
  ON cs_sample.cs_promo_sk = promo2.p_promo_sk
JOIN ship_mode AS sm2
  ON cs_sample.cs_ship_mode_sk = sm2.sm_ship_mode_sk
WHERE cs_sample.cs_order_number NOT IN (
    SELECT sr_ticket_number FROM store_returns
)
GROUP BY promo1.p_promo_name, sm1.sm_type, r2.r_reason_desc
ORDER BY total_profit DESC
LIMIT 100
