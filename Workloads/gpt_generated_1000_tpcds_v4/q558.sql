WITH base AS (
   SELECT DISTINCT
     c.c_customer_sk,
     c.c_customer_id,
     d.d_year,
     ss.ss_ext_sales_price,
     sr.sr_net_loss,
     ss.ss_ext_tax,
     r.r_reason_desc,
     ca.ca_state,
     cd.cd_gender
   FROM store_sales ss
   JOIN date_dim d
     ON ss.ss_sold_date_sk = d.d_date_sk
   JOIN customer c
     ON ss.ss_customer_sk = c.c_customer_sk
   JOIN customer_demographics cd
     ON ss.ss_cdemo_sk = cd.cd_demo_sk
   JOIN customer_address ca
     ON ss.ss_addr_sk = ca.ca_address_sk
   LEFT JOIN store_returns sr
     ON sr.sr_item_sk = ss.ss_item_sk
    AND sr.sr_ticket_number = ss.ss_ticket_number
    AND sr.sr_customer_sk = c.c_customer_sk
    AND sr.sr_cdemo_sk = cd.cd_demo_sk
    AND sr.sr_addr_sk = ca.ca_address_sk
   LEFT JOIN reason r
     ON sr.sr_reason_sk = r.r_reason_sk
   WHERE d.d_holiday = 'N'
     AND d.d_year = 2001
     AND c.c_preferred_cust_flag = 'Y'
     AND cd.cd_gender = 'M'
     AND ca.ca_state = 'CA'
     AND ss.ss_ext_tax > 10
     AND (r.r_reason_desc IS NULL OR r.r_reason_desc LIKE '%Defect%')
),
agg AS (
   SELECT
     c_customer_sk,
     c_customer_id,
     d_year,
     SUM(ss_ext_sales_price) AS total_sales,
     SUM(COALESCE(sr_net_loss, 0)) AS total_return_loss,
     COUNT(DISTINCT ss_ext_tax) AS distinct_tax_entries
   FROM base
   GROUP BY c_customer_sk, c_customer_id, d_year
)
SELECT
  c_customer_id,
  d_year,
  total_sales,
  total_return_loss,
  distinct_tax_entries,
  RANK() OVER (PARTITION BY d_year ORDER BY total_sales DESC) AS sales_rank,
  ROW_NUMBER() OVER (PARTITION BY d_year ORDER BY total_return_loss DESC) AS loss_row_num
FROM agg
WHERE total_sales > 5000
ORDER BY d_year, sales_rank
LIMIT 100
