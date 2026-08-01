WITH agg_store_sales AS (
   SELECT ss_store_sk,
          ss_sold_date_sk,
          SUM(ss_net_paid)   AS total_net_paid,
          SUM(ss_net_profit) AS total_net_profit,
          COUNT(*)           AS sales_cnt
   FROM tpcds.store_sales TABLESAMPLE BERNOULLI (10)
   GROUP BY ss_store_sk, ss_sold_date_sk
)
SELECT
   s1.s_store_name,
   d1.d_year,
   agg.total_net_paid,
   agg.total_net_profit,
   COUNT(DISTINCT cs.cs_order_number)                 AS catalog_orders,
   SUM(cs.cs_ext_tax)                                 AS total_catalog_tax,
   SUM(sr.sr_return_amt)                              AS total_return_amount,
   COUNT(DISTINCT sr.sr_ticket_number)               AS return_tickets,
   p1.p_promo_name,
   (SELECT AVG(p.p_cost) FROM tpcds.promotion p WHERE p.p_channel_tv = 'Y') AS avg_tv_promo_cost,
   cat_max.max_cat_sales_price
FROM agg_store_sales agg
JOIN tpcds.store s1
  ON agg.ss_store_sk = s1.s_store_sk
JOIN tpcds.date_dim d1
  ON agg.ss_sold_date_sk = d1.d_date_sk
JOIN tpcds.store_sales ss_detail
  ON ss_detail.ss_store_sk = agg.ss_store_sk
 AND ss_detail.ss_sold_date_sk = agg.ss_sold_date_sk
JOIN tpcds.promotion p1
  ON ss_detail.ss_promo_sk = p1.p_promo_sk
JOIN tpcds.catalog_sales cs
  ON cs.cs_sold_date_sk = d1.d_date_sk
JOIN tpcds.customer_demographics cd
  ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
JOIN tpcds.household_demographics hd
  ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
JOIN tpcds.income_band ib
  ON hd.hd_income_band_sk = ib.ib_income_band_sk
JOIN tpcds.customer_address ca
  ON cs.cs_bill_addr_sk = ca.ca_address_sk
JOIN tpcds.store_returns sr
  ON sr.sr_ticket_number = ss_detail.ss_ticket_number
 AND sr.sr_store_sk = s1.s_store_sk
 AND sr.sr_returned_date_sk = d1.d_date_sk
CROSS JOIN LATERAL (
   SELECT MAX(cs3.cs_ext_sales_price) AS max_cat_sales_price
   FROM tpcds.catalog_sales cs3
   WHERE cs3.cs_sold_date_sk = d1.d_date_sk
) AS cat_max
WHERE EXISTS (
   SELECT 1 FROM tpcds.store_returns sr_exist
   WHERE sr_exist.sr_store_sk = s1.s_store_sk
     AND sr_exist.sr_returned_date_sk = d1.d_date_sk
)
GROUP BY s1.s_store_name,
         d1.d_year,
         agg.total_net_paid,
         agg.total_net_profit,
         p1.p_promo_name,
         cat_max.max_cat_sales_price
UNION DISTINCT
SELECT
   s2.s_store_name,
   d2.d_year,
   0.0                                 AS total_net_paid,
   0.0                                 AS total_net_profit,
   0                                   AS catalog_orders,
   0.0                                 AS total_catalog_tax,
   SUM(sr2.sr_return_amt)              AS total_return_amount,
   COUNT(DISTINCT sr2.sr_ticket_number) AS return_tickets,
   CAST(NULL AS varchar)               AS promo_name,
   (SELECT AVG(p.p_cost) FROM tpcds.promotion p WHERE p.p_channel_tv = 'Y') AS avg_tv_promo_cost,
   0.0                                 AS max_catalog_sales_price
FROM agg_store_sales agg
JOIN tpcds.store s2
  ON agg.ss_store_sk = s2.s_store_sk
JOIN tpcds.date_dim d2
  ON s2.s_closed_date_sk = d2.d_date_sk
JOIN tpcds.store_returns sr2
  ON sr2.sr_store_sk = s2.s_store_sk
WHERE EXISTS (
   SELECT 1 FROM tpcds.store_returns sr_check
   WHERE sr_check.sr_store_sk = s2.s_store_sk
     AND sr_check.sr_returned_date_sk = d2.d_date_sk
)
GROUP BY s2.s_store_name, d2.d_year
ORDER BY total_net_paid DESC
OFFSET 0
LIMIT 100
