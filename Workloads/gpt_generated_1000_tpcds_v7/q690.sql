WITH sales_base AS (
   SELECT
       ss.ss_ticket_number,
       ss.ss_item_sk,
       ss.ss_quantity,
       ss.ss_ext_sales_price,
       ss.ss_net_paid,
       ss.ss_net_profit,
       c.c_customer_sk,
       c.c_first_name,
       c.c_last_name,
       c.c_birth_year,
       s.s_store_sk,
       s.s_store_name,
       s.s_gmt_offset
   FROM store_sales ss
   JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
   JOIN store s ON ss.ss_store_sk = s.s_store_sk
   WHERE s.s_gmt_offset > -5
     AND c.c_birth_year BETWEEN 1950 AND 1990
     AND ss.ss_ext_list_price > 5000
),
returns_joined AS (
   SELECT
       sb.c_customer_sk,
       sb.c_first_name,
       sb.c_last_name,
       sb.s_store_name,
       sb.s_gmt_offset,
       sr.sr_return_amt,
       sr.sr_net_loss,
       sr.sr_reversed_charge,
       sr.sr_store_credit,
       sr.sr_refunded_cash,
       wr.wr_return_amt,
       wr.wr_fee
   FROM sales_base sb
   JOIN store_returns sr
       ON sr.sr_ticket_number = sb.ss_ticket_number
      AND sr.sr_item_sk = sb.ss_item_sk
      AND sr.sr_customer_sk = sb.c_customer_sk
      AND sr.sr_store_sk = sb.s_store_sk
   JOIN web_returns wr
       ON wr.wr_refunded_customer_sk = sb.c_customer_sk
   WHERE sr.sr_reversed_charge > 50
     AND sr.sr_store_credit > 0
     AND sr.sr_refunded_cash > 100
     AND wr.wr_return_amt > 1000
     AND wr.wr_fee < 50
     AND sb.ss_quantity >= 1
)
SELECT
   r.c_customer_sk,
   r.c_first_name,
   r.c_last_name,
   r.s_store_name,
   SUM(r.sr_return_amt) AS total_return_amount,
   SUM(r.sr_net_loss) AS total_net_loss,
   AVG(r.wr_return_amt) AS avg_web_return_amt,
   ROW_NUMBER() OVER (PARTITION BY r.s_store_name ORDER BY SUM(r.sr_net_loss) DESC) AS store_customer_rank,
   (SELECT AVG(wr2.wr_return_amt)
      FROM web_returns wr2
     WHERE wr2.wr_refunded_customer_sk = r.c_customer_sk) AS customer_avg_web_return
FROM returns_joined r
GROUP BY r.c_customer_sk, r.c_first_name, r.c_last_name, r.s_store_name, r.s_gmt_offset
ORDER BY store_customer_rank
