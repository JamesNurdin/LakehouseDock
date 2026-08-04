WITH catalog_ret_agg AS (
   SELECT cr_returned_date_sk,
          cr_item_sk,
          cr_reason_sk,
          SUM(cr_return_amount)          AS total_return_amount,
          SUM(cr_return_quantity)        AS total_return_quantity,
          COUNT(*)                       AS cnt_returns
   FROM catalog_returns
   WHERE cr_returned_date_sk IN (
         SELECT d_date_sk
         FROM date_dim
         WHERE d_year = 2001
   )
   GROUP BY cr_returned_date_sk, cr_item_sk, cr_reason_sk
),
base_join AS (
   SELECT d.d_year,
          i.i_category,
          i.i_brand,
          r.r_reason_desc,
          ss.ss_ext_sales_price,
          ss.ss_ext_discount_amt,
          cra.total_return_amount,
          c.c_customer_sk,
          cc.cc_state,
          ib.ib_upper_bound,
          p.p_discount_active,
          i.i_item_sk,
          d.d_date_sk
   FROM catalog_returns cr
   JOIN catalog_ret_agg cra
     ON cr.cr_returned_date_sk = cra.cr_returned_date_sk
    AND cr.cr_item_sk           = cra.cr_item_sk
    AND cr.cr_reason_sk         = cra.cr_reason_sk
   JOIN call_center cc
     ON cr.cr_call_center_sk = cc.cc_call_center_sk
   JOIN reason r
     ON cr.cr_reason_sk = r.r_reason_sk
   JOIN item i
     ON cr.cr_item_sk = i.i_item_sk
   JOIN date_dim d
     ON cr.cr_returned_date_sk = d.d_date_sk
   JOIN household_demographics hd
     ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
   JOIN income_band ib
     ON hd.hd_income_band_sk = ib.ib_income_band_sk
   JOIN customer_address ca
     ON cr.cr_refunded_addr_sk = ca.ca_address_sk
   JOIN store_sales ss
     ON ss.ss_item_sk     = i.i_item_sk
    AND ss.ss_sold_date_sk = d.d_date_sk
   JOIN customer c
     ON ss.ss_customer_sk = c.c_customer_sk
   JOIN customer_demographics cd
     ON ss.ss_cdemo_sk = cd.cd_demo_sk
   JOIN promotion p
     ON ss.ss_promo_sk = p.p_promo_sk
   JOIN ship_mode sm
     ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
   JOIN web_sales ws
     ON ws.ws_item_sk     = i.i_item_sk
    AND ws.ws_sold_date_sk = d.d_date_sk
   JOIN web_site wsite
     ON ws.ws_web_site_sk = wsite.web_site_sk
   JOIN web_returns wr
     ON wr.wr_order_number = ws.ws_order_number
    AND wr.wr_item_sk      = i.i_item_sk
   WHERE ib.ib_upper_bound >= 80000
     AND p.p_discount_active = 'Y'
     AND cc.cc_state = 'CA'
     AND EXISTS (
          SELECT 1
          FROM web_returns wr2
          WHERE wr2.wr_item_sk = i.i_item_sk
            AND wr2.wr_returned_date_sk = d.d_date_sk
     )
),
sales_agg AS (
   SELECT d_year,
          i_category,
          i_brand,
          r_reason_desc,
          SUM(ss_ext_sales_price) AS total_sales,
          SUM(ss_ext_discount_amt) AS total_discount,
          SUM(total_return_amount) AS total_returns,
          COUNT(DISTINCT c_customer_sk) AS num_customers,
          COUNT(*) AS num_transactions
   FROM base_join
   GROUP BY d_year, i_category, i_brand, r_reason_desc
   HAVING SUM(ss_ext_sales_price) > 10000
)
SELECT d_year,
       i_category,
       i_brand,
       r_reason_desc,
       total_sales,
       total_discount,
       total_returns,
       num_customers,
       num_transactions,
       ROW_NUMBER() OVER (PARTITION BY i_category ORDER BY total_sales DESC) AS sales_rank
FROM sales_agg
ORDER BY total_sales DESC
LIMIT 100
