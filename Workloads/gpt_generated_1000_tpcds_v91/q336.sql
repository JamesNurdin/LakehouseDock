WITH full_sales_returns AS (
   SELECT
       COALESCE(ss.ss_ticket_number, sr.sr_ticket_number) AS ticket_number,
       COALESCE(ss.ss_sold_date_sk, sr.sr_returned_date_sk) AS sale_date_sk,
       COALESCE(ss.ss_customer_sk, sr.sr_customer_sk) AS customer_sk,
       COALESCE(ss.ss_hdemo_sk, sr.sr_hdemo_sk) AS hdemo_sk,
       ss.ss_net_paid,
       ss.ss_net_paid_inc_tax,
       sr.sr_return_amt,
       sr.sr_return_tax
   FROM store_sales ss
   FULL OUTER JOIN store_returns sr
     ON ss.ss_ticket_number = sr.sr_ticket_number
),
customer_aggregates AS (
   SELECT
       c.c_customer_sk,
       c.c_first_name,
       c.c_last_name,
       c.c_customer_id,
       c.c_preferred_cust_flag,
       c.c_first_sales_date_sk,
       hd.hd_buy_potential,
       d.d_year,
       SUM(COALESCE(fsr.ss_net_paid, 0)) AS total_net_paid,
       SUM(COALESCE(fsr.sr_return_amt, 0)) AS total_return_amt,
       COUNT(*) AS transaction_cnt
   FROM full_sales_returns fsr
   JOIN customer c
     ON c.c_customer_sk = fsr.customer_sk
   LEFT JOIN household_demographics hd
     ON hd.hd_demo_sk = fsr.hdemo_sk
   LEFT JOIN date_dim d
     ON d.d_date_sk = fsr.sale_date_sk
   WHERE NOT EXISTS (
        SELECT 1
        FROM catalog_sales cs
        WHERE cs.cs_bill_customer_sk = c.c_customer_sk
          AND cs.cs_sold_date_sk = d.d_date_sk
   )
   GROUP BY
       c.c_customer_sk,
       c.c_first_name,
       c.c_last_name,
       c.c_customer_id,
       c.c_preferred_cust_flag,
       c.c_first_sales_date_sk,
       hd.hd_buy_potential,
       d.d_year
   HAVING SUM(COALESCE(fsr.ss_net_paid, 0)) > 10000
),
customer_with_site AS (
   SELECT
       ca.*,
       w.web_city,
       w.web_tax_percentage
   FROM customer_aggregates ca
   JOIN date_dim d2
     ON d2.d_date_sk = ca.c_first_sales_date_sk
   JOIN web_site w
     ON w.web_open_date_sk = d2.d_date_sk
   WHERE regexp_like(w.web_city, '^G.*')
     AND w.web_city LIKE '%town%'
),
final AS (
   SELECT
       cws.c_customer_sk,
       cws.c_first_name,
       cws.c_last_name,
       CONCAT(cws.c_first_name, ' ', cws.c_last_name) AS full_name,
       cws.c_customer_id,
       lc.cust_id_num,
       cws.hd_buy_potential,
       cws.d_year,
       cws.total_net_paid,
       cws.total_return_amt,
       cws.transaction_cnt,
       cws.web_city,
       cws.web_tax_percentage,
       (SELECT SUM(sr3.sr_return_amt)
        FROM store_returns sr3
        WHERE sr3.sr_customer_sk = cws.c_customer_sk) AS total_return_amt_all,
       RANK() OVER (PARTITION BY cws.c_preferred_cust_flag ORDER BY cws.total_net_paid DESC) AS rank_by_preferred_flag
   FROM customer_with_site cws
   CROSS JOIN LATERAL (
         SELECT regexp_extract(cws.c_customer_id, '(\\d+)', 1) AS cust_id_num
   ) lc
)
SELECT
    c_customer_sk,
    full_name,
    cust_id_num,
    hd_buy_potential,
    d_year,
    total_net_paid,
    total_return_amt,
    total_return_amt_all,
    transaction_cnt,
    web_city,
    web_tax_percentage,
    rank_by_preferred_flag
FROM final
ORDER BY total_net_paid DESC, rank_by_preferred_flag
LIMIT 100
