SELECT
    c.c_customer_id,
    c.c_birth_year,
    SUM(cs.cs_net_profit) AS total_profit,
    COUNT(DISTINCT cs.cs_order_number) AS order_cnt,
    (SELECT hd2.hd_buy_potential FROM household_demographics hd2 LIMIT 1) AS sample_buy_potential
FROM catalog_sales cs
JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
JOIN store_returns sr ON sr.sr_customer_sk = c.c_customer_sk
WHERE cs.cs_sold_date_sk = 2450839
  AND sr.sr_returned_date_sk = 2451280
GROUP BY c.c_customer_id, c.c_birth_year
HAVING SUM(cs.cs_net_profit) > -1569.47
