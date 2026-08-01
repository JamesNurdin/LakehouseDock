WITH union_sales AS (
    SELECT cs_sold_date_sk AS sold_date_sk,
           cs_bill_customer_sk AS customer_sk,
           cs_bill_cdemo_sk AS cdemo_sk,
           cs_bill_hdemo_sk AS hdemo_sk,
           cs_net_paid_inc_tax AS net_paid
    FROM catalog_sales
    UNION ALL
    SELECT ss_sold_date_sk AS sold_date_sk,
           ss_customer_sk AS customer_sk,
           ss_cdemo_sk AS cdemo_sk,
           ss_hdemo_sk AS hdemo_sk,
           ss_net_paid_inc_tax AS net_paid
    FROM store_sales
)
SELECT
    c.c_customer_id,
    cd.cd_gender,
    hd.hd_buy_potential,
    SUM(u.net_paid) AS total_net_paid,
    COUNT(*) AS sales_cnt,
    AVG(u.net_paid) AS avg_net_paid
FROM union_sales u
JOIN customer c
  ON u.customer_sk = c.c_customer_sk
JOIN customer_demographics cd
  ON u.cdemo_sk = cd.cd_demo_sk
JOIN household_demographics hd
  ON u.hdemo_sk = hd.hd_demo_sk
JOIN catalog_sales cs_bill
  ON cs_bill.cs_bill_customer_sk = c.c_customer_sk
 AND cs_bill.cs_bill_cdemo_sk = cd.cd_demo_sk
 AND cs_bill.cs_bill_hdemo_sk = hd.hd_demo_sk
JOIN catalog_sales cs_ship
  ON cs_ship.cs_ship_customer_sk = c.c_customer_sk
 AND cs_ship.cs_ship_cdemo_sk = cd.cd_demo_sk
 AND cs_ship.cs_ship_hdemo_sk = hd.hd_demo_sk
JOIN store_sales ss
  ON ss.ss_customer_sk = c.c_customer_sk
 AND ss.ss_cdemo_sk = cd.cd_demo_sk
 AND ss.ss_hdemo_sk = hd.hd_demo_sk
JOIN customer_demographics cd_curr
  ON c.c_current_cdemo_sk = cd_curr.cd_demo_sk
JOIN household_demographics hd_curr
  ON c.c_current_hdemo_sk = hd_curr.hd_demo_sk
JOIN catalog_sales cs_extra
  ON cs_extra.cs_ship_customer_sk = c.c_customer_sk
 AND cs_extra.cs_ship_cdemo_sk = cd.cd_demo_sk
 AND cs_extra.cs_ship_hdemo_sk = hd.hd_demo_sk
WHERE EXISTS (
    SELECT 1
    FROM catalog_sales cs_sub
    WHERE cs_sub.cs_net_paid_inc_tax > 5000
      AND cs_sub.cs_bill_customer_sk = c.c_customer_sk
)
  AND c.c_salutation = 'Mr.'
GROUP BY c.c_customer_id, cd.cd_gender, hd.hd_buy_potential
ORDER BY total_net_paid DESC
LIMIT 100
