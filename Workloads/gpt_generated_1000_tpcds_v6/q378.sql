WITH sales_agg AS (
   SELECT
      c.c_customer_id AS customer_id,
      cd.cd_gender AS gender,
      hd.hd_buy_potential AS buy_potential,
      p.p_promo_name AS promo_name,
      SUM(ss.ss_ext_sales_price) AS store_sales_amount,
      SUM(ws.ws_ext_sales_price) AS web_sales_amount,
      COUNT(DISTINCT ss.ss_ticket_number) AS store_txn_cnt,
      COUNT(DISTINCT ws.ws_order_number) AS web_txn_cnt,
      SUM(ss.ss_ext_sales_price) + SUM(ws.ws_ext_sales_price) AS total_sales
   FROM store_sales ss
   JOIN customer c
     ON ss.ss_customer_sk = c.c_customer_sk
   JOIN customer_demographics cd
     ON ss.ss_cdemo_sk = cd.cd_demo_sk
   JOIN household_demographics hd
     ON ss.ss_hdemo_sk = hd.hd_demo_sk
   JOIN promotion p
     ON ss.ss_promo_sk = p.p_promo_sk
   JOIN web_sales ws
     ON ws.ws_bill_customer_sk = c.c_customer_sk
    AND ws.ws_bill_cdemo_sk = cd.cd_demo_sk
    AND ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    AND ws.ws_promo_sk = p.p_promo_sk
   WHERE
      c.c_preferred_cust_flag = 'Y'
      AND cd.cd_gender = 'M'
      AND hd.hd_buy_potential = '5001-10000'
      AND p.p_channel_email = 'N'
      AND ss.ss_sold_date_sk BETWEEN 2450815 AND 2451179
      AND ws.ws_sold_date_sk BETWEEN 2450815 AND 2451179
      AND ss.ss_quantity > 1
      AND ws.ws_quantity > 1
   GROUP BY
      c.c_customer_id,
      cd.cd_gender,
      hd.hd_buy_potential,
      p.p_promo_name
   HAVING
      SUM(ss.ss_ext_sales_price) > 1000
      AND SUM(ws.ws_ext_sales_price) > 500
)
SELECT
   customer_id,
   gender,
   buy_potential,
   promo_name,
   store_sales_amount,
   web_sales_amount,
   total_sales,
   ROW_NUMBER() OVER (PARTITION BY gender ORDER BY total_sales DESC) AS gender_rank,
   SUM(total_sales) OVER (
       PARTITION BY buy_potential
       ORDER BY total_sales
       ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
   ) AS cumulative_sales_by_buy_potential
FROM sales_agg
WHERE total_sales > (
   SELECT AVG(total_sales) FROM sales_agg
)
ORDER BY total_sales DESC
LIMIT 100
