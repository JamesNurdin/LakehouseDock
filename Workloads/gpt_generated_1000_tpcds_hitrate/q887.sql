WITH
base_sales AS (
   SELECT
       ss.ss_ticket_number,
       ss.ss_sold_date_sk,
       ss.ss_sold_time_sk,
       ss.ss_customer_sk,
       ss.ss_cdemo_sk,
       ss.ss_hdemo_sk,
       ss.ss_addr_sk,
       ss.ss_net_paid,
       ss.ss_net_profit,
       ss.ss_ext_sales_price,
       c.c_first_name,
       c.c_last_name,
       cd.cd_gender,
       cd.cd_purchase_estimate AS purchase_estimate,
       hd.hd_income_band_sk AS income_band,
       ca.ca_state,
       t.t_hour,
       t.t_shift
   FROM store_sales ss
   JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
   JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
   JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
   JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
   JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
   WHERE cd.cd_gender = 'F'
     AND hd.hd_income_band_sk BETWEEN 5 AND 15
     AND ca.ca_state = 'CA'
     AND t.t_hour BETWEEN 9 AND 17
),
intersect_customers AS (
   SELECT cr.cr_refunded_customer_sk AS customer_sk
   FROM catalog_returns cr
   WHERE cr.cr_return_amount > 1000
   INTERSECT
   SELECT wr.wr_refunded_customer_sk
   FROM web_returns wr
   WHERE wr.wr_return_amt > 1000
),
returns_agg AS (
   SELECT
       cr.cr_refunded_customer_sk AS customer_sk,
       SUM(cr.cr_return_amount) AS total_return_amount,
       COUNT(*) AS return_cnt,
       cc.cc_name,
       cp.cp_department,
       r.r_reason_desc
   FROM catalog_returns cr
   JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
   JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
   JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
   WHERE cr.cr_return_quantity > 0
   GROUP BY cr.cr_refunded_customer_sk, cc.cc_name, cp.cp_department, r.r_reason_desc
),
distinct_reasons AS (
   SELECT DISTINCT r.r_reason_desc
   FROM reason r
   WHERE r.r_reason_sk IN (SELECT cr_reason_sk FROM catalog_returns WHERE cr_return_amount > 2000)
),
scalar_max_paid AS (
   SELECT MAX(ss_net_paid) AS max_paid
   FROM store_sales
   WHERE ss_sold_date_sk = 2451545
)
SELECT
   bs.ss_ticket_number,
   bs.c_first_name,
   bs.c_last_name,
   bs.ca_state,
   bs.t_hour,
   ra.total_return_amount,
   ra.return_cnt,
   ra.cc_name,
   ra.cp_department,
   dr.r_reason_desc,
   bs.ss_net_paid,
   bs.ss_net_profit,
   CASE WHEN bs.ss_net_profit > 0 THEN 'PROFIT' ELSE 'LOSS' END AS profit_flag,
   ROW_NUMBER() OVER (PARTITION BY bs.ca_state ORDER BY bs.ss_net_profit DESC) AS profit_rank,
   (SELECT max_paid FROM scalar_max_paid) AS max_paid_global
FROM base_sales bs
JOIN intersect_customers ic ON bs.ss_customer_sk = ic.customer_sk
JOIN returns_agg ra ON bs.ss_customer_sk = ra.customer_sk
JOIN distinct_reasons dr ON ra.r_reason_desc = dr.r_reason_desc
WHERE bs.ss_net_paid > (SELECT max_paid FROM scalar_max_paid) * 0.5
  AND ra.total_return_amount > 5000
  AND bs.ss_ext_sales_price > 1000
  AND bs.purchase_estimate BETWEEN 3000 AND 8000
  AND bs.income_band <> 10
  AND bs.t_shift = 'AFTERNOON'
ORDER BY profit_rank, bs.ss_net_paid DESC
LIMIT 100
