WITH
  promo_distinct AS (
    SELECT DISTINCT p.p_promo_sk,
           p.p_promo_name,
           p.p_discount_active
    FROM   promotion p
    WHERE  p.p_discount_active = 'Y'
  ),
  sales_base AS (
    SELECT
      ss.ss_ticket_number,
      ss.ss_sold_date_sk,
      ss.ss_store_sk,
      ss.ss_cdemo_sk,
      ss.ss_hdemo_sk,
      ss.ss_promo_sk,
      ss.ss_net_paid_inc_tax,
      ss.ss_ext_sales_price,
      ss.ss_ext_discount_amt,
      sr.sr_return_quantity,
      sr.sr_net_loss,
      s.s_store_name,
      s.s_state,
      cd.cd_marital_status,
      hd.hd_income_band_sk,
      ib.ib_lower_bound,
      ib.ib_upper_bound,
      pd.p_promo_name
    FROM   store_sales ss
    JOIN   store s
      ON   ss.ss_store_sk = s.s_store_sk
    JOIN   customer_demographics cd
      ON   ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN   household_demographics hd
      ON   ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN   income_band ib
      ON   hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN   promo_distinct pd
      ON   ss.ss_promo_sk = pd.p_promo_sk
    LEFT JOIN store_returns sr
      ON   ss.ss_ticket_number = sr.sr_ticket_number
    WHERE
      s.s_state = 'TX'               -- store location filter
      AND cd.cd_marital_status = 'M' -- customer marital status filter
      AND ib.ib_upper_bound <= 50000 -- income band filter
  ),
  catalog_base AS (
    SELECT
      cr.cr_returned_date_sk,
      cr.cr_call_center_sk,
      cr.cr_return_amount,
      cr.cr_store_credit,
      cc.cc_name,
      cc.cc_state,
      cc.cc_gmt_offset,
      cd2.cd_demo_sk,
      cd2.cd_marital_status AS cd2_marital_status,
      hd2.hd_demo_sk,
      ib2.ib_lower_bound AS ib2_lower,
      ib2.ib_upper_bound AS ib2_upper
    FROM   catalog_returns cr
    JOIN   call_center cc
      ON   cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN   customer_demographics cd2
      ON   cr.cr_refunded_cdemo_sk = cd2.cd_demo_sk
    JOIN   household_demographics hd2
      ON   cr.cr_refunded_hdemo_sk = hd2.hd_demo_sk
    JOIN   income_band ib2
      ON   hd2.hd_income_band_sk = ib2.ib_income_band_sk
    WHERE
      cc.cc_state = 'CA'                -- call‑center location filter
      AND cc.cc_gmt_offset BETWEEN -5 AND 5 -- GMT offset filter
      AND cr.cr_store_credit > 100.00    -- high store‑credit returns filter
  )
SELECT
  COALESCE(sb.s_store_name, cb.cc_name)            AS location_name,
  COALESCE(sb.s_state,        cb.cc_state)         AS region_state,
  SUM(COALESCE(sb.ss_ext_sales_price, 0))          AS total_sales_amount,
  SUM(COALESCE(sb.sr_net_loss, 0))                 AS total_store_return_loss,
  SUM(COALESCE(cb.cr_return_amount, 0))            AS total_catalog_return_amount,
  COUNT(DISTINCT sb.ss_ticket_number)             AS distinct_sales_tickets,
  AVG(sb.ss_net_paid_inc_tax)                     AS avg_net_paid_inc_tax,
  MIN(sb.ib_lower_bound)                          AS min_income_lower_bound,
  MAX(sb.ib_upper_bound)                          AS max_income_upper_bound
FROM   sales_base sb
FULL   OUTER JOIN catalog_base cb
       ON sb.ss_cdemo_sk = cb.cd_demo_sk
GROUP  BY 1, 2
ORDER  BY total_sales_amount DESC
LIMIT  100
