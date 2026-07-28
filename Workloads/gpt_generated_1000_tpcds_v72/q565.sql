/*
Goal: Analyse profitability by calendar year, promotion, call‑center and return reason by combining store sales, catalog sales and web returns.
The query joins all twelve selected TPC‑DS tables, re‑uses the DATE_DIM, PROMOTION and other dimension tables under different aliases, aggregates net amounts, applies a HAVING filter, ranks the groups, orders by profit and limits the output.
*/
WITH
  -- Join store sales to its dimensions
  ss_base AS (
    SELECT
      ss.ss_sold_date_sk,
      ss.ss_net_paid,
      ss.ss_customer_sk,
      ss.ss_hdemo_sk,
      ss.ss_addr_sk,
      ss.ss_promo_sk
    FROM store_sales ss
  ),
  -- Join catalog sales to its dimensions (bill side) and to call‑center & catalog page
  cs_base AS (
    SELECT
      cs.cs_sold_date_sk,
      cs.cs_net_paid,
      cs.cs_bill_customer_sk,
      cs.cs_bill_hdemo_sk,
      cs.cs_bill_addr_sk,
      cs.cs_call_center_sk,
      cs.cs_catalog_page_sk,
      cs.cs_promo_sk
    FROM catalog_sales cs
  ),
  -- Join web returns to its dimensions
  wr_base AS (
    SELECT
      wr.wr_returned_date_sk,
      wr.wr_net_loss,
      wr.wr_refunded_customer_sk,
      wr.wr_refunded_hdemo_sk,
      wr.wr_refunded_addr_sk,
      wr.wr_reason_sk
    FROM web_returns wr
  )
SELECT
  d_ss.d_year                                   AS year,
  p_ss.p_promo_name                             AS promo_name,
  cc.cc_name                                    AS call_center_name,
  r.r_reason_desc                               AS return_reason,
  SUM(ssb.ss_net_paid)                         AS total_store_sales,
  SUM(csb.cs_net_paid)                         AS total_catalog_sales,
  SUM(wrb.wr_net_loss)                         AS total_return_loss,
  (SUM(ssb.ss_net_paid) + SUM(csb.cs_net_paid) - SUM(wrb.wr_net_loss)) AS total_net_profit,
  RANK() OVER (ORDER BY (SUM(ssb.ss_net_paid) + SUM(csb.cs_net_paid) - SUM(wrb.wr_net_loss)) DESC) AS profit_rank
FROM ss_base ssb
JOIN date_dim d_ss
  ON ssb.ss_sold_date_sk = d_ss.d_date_sk
JOIN customer c_ss
  ON ssb.ss_customer_sk = c_ss.c_customer_sk
JOIN household_demographics hd_ss
  ON ssb.ss_hdemo_sk = hd_ss.hd_demo_sk
JOIN customer_address ca_ss
  ON ssb.ss_addr_sk = ca_ss.ca_address_sk
JOIN promotion p_ss
  ON ssb.ss_promo_sk = p_ss.p_promo_sk
JOIN income_band ib_ss
  ON hd_ss.hd_income_band_sk = ib_ss.ib_income_band_sk

JOIN cs_base csb
  ON csb.cs_bill_customer_sk = c_ss.c_customer_sk
  AND csb.cs_bill_hdemo_sk = hd_ss.hd_demo_sk
  AND csb.cs_bill_addr_sk = ca_ss.ca_address_sk
JOIN date_dim d_cs
  ON csb.cs_sold_date_sk = d_cs.d_date_sk
JOIN call_center cc
  ON csb.cs_call_center_sk = cc.cc_call_center_sk
JOIN catalog_page cp
  ON csb.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN promotion p_cs
  ON csb.cs_promo_sk = p_cs.p_promo_sk

JOIN wr_base wrb
  ON wrb.wr_refunded_customer_sk = c_ss.c_customer_sk
  AND wrb.wr_refunded_hdemo_sk = hd_ss.hd_demo_sk
  AND wrb.wr_refunded_addr_sk = ca_ss.ca_address_sk
JOIN date_dim d_wr
  ON wrb.wr_returned_date_sk = d_wr.d_date_sk
JOIN reason r
  ON wrb.wr_reason_sk = r.r_reason_sk
WHERE d_ss.d_year = 2001
GROUP BY
  d_ss.d_year,
  p_ss.p_promo_name,
  cc.cc_name,
  r.r_reason_desc
HAVING (SUM(ssb.ss_net_paid) + SUM(csb.cs_net_paid) - SUM(wrb.wr_net_loss)) > 10000
ORDER BY total_net_profit DESC
LIMIT 100
