WITH store_agg AS (
   SELECT
       ss_sold_time_sk AS time_sk,
       ss_promo_sk AS promo_sk,
       SUM(ss_ext_tax)        AS total_tax,
       SUM(ss_net_paid)      AS total_paid
   FROM store_sales
   WHERE ss_ext_tax < 50
   GROUP BY ss_sold_time_sk, ss_promo_sk
)
SELECT
   td.t_hour,
   p.p_promo_name,
   cp.cp_department,
   ib.ib_upper_bound,
   COUNT(DISTINCT cs.cs_order_number)            AS orders,
   SUM(cs.cs_ext_sales_price)                    AS catalog_sales_amount,
   SUM(r.cr_return_amount)                       AS total_returns,
   sa.total_tax,
   sa.total_paid
FROM store_agg sa
JOIN time_dim td
  ON sa.time_sk = td.t_time_sk
JOIN promotion p
  ON sa.promo_sk = p.p_promo_sk
JOIN catalog_sales cs
  ON cs.cs_sold_time_sk = td.t_time_sk
 AND cs.cs_promo_sk = p.p_promo_sk
JOIN catalog_page cp
  ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN catalog_returns r
  ON r.cr_order_number = cs.cs_order_number
 AND r.cr_item_sk = cs.cs_item_sk
 AND r.cr_returned_time_sk = td.t_time_sk
JOIN customer_demographics cd
  ON cd.cd_demo_sk = cs.cs_bill_cdemo_sk
JOIN household_demographics hd
  ON hd.hd_demo_sk = cs.cs_bill_hdemo_sk
JOIN income_band ib
  ON hd.hd_income_band_sk = ib.ib_income_band_sk
WHERE ib.ib_upper_bound > 100000
  AND p.p_discount_active = 'Y'
  AND td.t_hour BETWEEN 9 AND 17
  AND cs.cs_net_paid_inc_tax > 2000
GROUP BY
   td.t_hour,
   p.p_promo_name,
   cp.cp_department,
   ib.ib_upper_bound,
   sa.total_tax,
   sa.total_paid
HAVING SUM(cs.cs_ext_sales_price) > 5000
ORDER BY catalog_sales_amount DESC
LIMIT 100
