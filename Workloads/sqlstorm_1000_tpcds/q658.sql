WITH sales_union AS (
 SELECT cs.cs_bill_customer_sk AS cust_sk,
        cs.cs_sold_date_sk AS date_sk,
        cs.cs_net_paid AS net_paid,
        cs.cs_net_profit AS net_profit,
        'catalog' AS channel,
        cs.cs_order_number AS order_number,
        NULL AS ticket_number,
        cs.cs_coupon_amt AS coupon_amt
   FROM catalog_sales cs
 UNION ALL
 SELECT ss.ss_customer_sk AS cust_sk,
        ss.ss_sold_date_sk AS date_sk,
        ss.ss_net_paid AS net_paid,
        ss.ss_net_profit AS net_profit,
        'store' AS channel,
        NULL AS order_number,
        ss.ss_ticket_number AS ticket_number,
        ss.ss_coupon_amt AS coupon_amt
   FROM store_sales ss
 UNION ALL
 SELECT ws.ws_bill_customer_sk AS cust_sk,
        ws.ws_sold_date_sk AS date_sk,
        ws.ws_net_paid AS net_paid,
        ws.ws_net_profit AS net_profit,
        'web' AS channel,
        ws.ws_order_number AS order_number,
        NULL AS ticket_number,
        ws.ws_coupon_amt AS coupon_amt
   FROM web_sales ws
),
returns_union AS (
 SELECT cr.cr_refunded_customer_sk AS cust_sk,
        cr.cr_returned_date_sk AS date_sk,
        cr.cr_return_amount AS return_amount,
        cr.cr_net_loss AS net_loss,
        'catalog' AS channel,
        cr.cr_order_number AS order_number,
        NULL AS ticket_number
   FROM catalog_returns cr
 UNION ALL
 SELECT sr.sr_customer_sk AS cust_sk,
        sr.sr_returned_date_sk AS date_sk,
        sr.sr_return_amt AS return_amount,
        sr.sr_net_loss AS net_loss,
        'store' AS channel,
        NULL AS order_number,
        sr.sr_ticket_number AS ticket_number
   FROM store_returns sr
 UNION ALL
 SELECT wr.wr_refunded_customer_sk AS cust_sk,
        wr.wr_returned_date_sk AS date_sk,
        wr.wr_return_amt AS return_amount,
        wr.wr_net_loss AS net_loss,
        'web' AS channel,
        wr.wr_order_number AS order_number,
        NULL AS ticket_number
   FROM web_returns wr
),
sales_with_returns AS (
 SELECT
   s.cust_sk,
   s.channel,
   s.date_sk,
   d.d_year,
   s.net_paid,
   s.net_profit,
   COALESCE(r.return_amount, 0) AS return_amount,
   COALESCE(r.net_loss, 0) AS net_loss,
   CASE WHEN s.net_paid > 0 THEN s.net_profit / s.net_paid ELSE NULL END AS profit_margin,
   CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
   COALESCE(c.c_preferred_cust_flag, 'N') AS pref_flag,
   cd.cd_gender AS gender
 FROM sales_union s
 LEFT JOIN returns_union r
   ON s.channel = r.channel
  AND (
        (s.channel = 'catalog' AND s.order_number = r.order_number)
     OR (s.channel = 'store' AND s.ticket_number = r.ticket_number)
     OR (s.channel = 'web' AND s.order_number = r.order_number)
      )
  AND s.cust_sk = r.cust_sk
  AND s.date_sk = r.date_sk
 JOIN date_dim d ON s.date_sk = d.d_date_sk
 JOIN customer c ON s.cust_sk = c.c_customer_sk
 LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
 WHERE d.d_year = 2001
   AND (s.net_paid > 0 OR r.return_amount IS NOT NULL)
),
customer_agg AS (
 SELECT
   cust_sk,
   full_name,
   pref_flag,
   gender,
   SUM(net_paid) AS total_net_paid,
   SUM(net_profit) AS total_net_profit,
   SUM(return_amount) AS total_return_amount,
   SUM(net_loss) AS total_net_loss,
   COUNT(DISTINCT channel) AS channel_count,
   MAX(profit_margin) AS max_profit_margin,
   MIN(profit_margin) AS min_profit_margin,
   AVG(profit_margin) AS avg_profit_margin
 FROM sales_with_returns
 GROUP BY cust_sk, full_name, pref_flag, gender
),
ranked_customers AS (
 SELECT
   cust_sk,
   full_name,
   pref_flag,
   gender,
   total_net_paid,
   total_net_profit,
   total_return_amount,
   total_net_loss,
   channel_count,
   max_profit_margin,
   min_profit_margin,
   avg_profit_margin,
   RANK() OVER (ORDER BY total_net_paid DESC) AS net_paid_rank,
   ROW_NUMBER() OVER (PARTITION BY pref_flag ORDER BY total_net_profit DESC) AS pref_flag_profit_rank
 FROM customer_agg
)
SELECT
  rc.cust_sk,
  rc.full_name,
  rc.pref_flag,
  CASE WHEN rc.gender IS NULL THEN 'Unknown' ELSE rc.gender END AS gender_label,
  rc.total_net_paid,
  rc.total_net_profit,
  rc.total_return_amount,
  rc.total_net_loss,
  rc.channel_count,
  rc.max_profit_margin,
  rc.min_profit_margin,
  rc.avg_profit_margin,
  rc.net_paid_rank,
  rc.pref_flag_profit_rank,
  CASE WHEN rc.total_net_paid = 0 THEN NULL ELSE rc.total_net_profit / rc.total_net_paid END AS overall_profit_ratio,
  CONCAT('Cust', CAST(rc.cust_sk AS VARCHAR)) AS cust_code,
  (SELECT AVG(ca.total_net_profit) FROM customer_agg ca WHERE ca.pref_flag = rc.pref_flag) AS avg_profit_same_pref_flag,
  (SELECT AVG(ca.total_net_profit) FROM customer_agg ca WHERE ca.gender = rc.gender) AS avg_profit_same_gender
FROM ranked_customers rc
WHERE rc.net_paid_rank <= 10
   OR rc.pref_flag_profit_rank <= 5
ORDER BY rc.net_paid_rank ASC, rc.pref_flag_profit_rank ASC
