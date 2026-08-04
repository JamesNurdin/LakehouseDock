WITH
inv_agg AS (
   SELECT inv_item_sk,
          inv_date_sk,
          SUM(inv_quantity_on_hand) AS total_qty
   FROM inventory
   WHERE inv_quantity_on_hand > 0
   GROUP BY inv_item_sk, inv_date_sk
),
scalar_max_promo AS (
   SELECT MAX(p_cost) AS max_cost
   FROM promotion
   WHERE p_channel_event = 'N'
),
store_sales_yr AS (
   SELECT ss.*, d.d_year, d.d_month_seq
   FROM store_sales ss
   JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
   WHERE d.d_year = 2001
),
catalog_returns_yr AS (
   SELECT cr.*, d2.d_year AS return_year
   FROM catalog_returns cr
   JOIN date_dim d2 ON cr.cr_returned_date_sk = d2.d_date_sk
   WHERE d2.d_year = 2001
),
intersect_stores AS (
   SELECT ss_store_sk FROM store_sales_yr
   INTERSECT
   SELECT cr_returning_customer_sk FROM catalog_returns_yr
)
SELECT
    s.s_store_name,
    s.s_tax_percentage,
    i.i_brand,
    cd.cd_gender,
    hd.hd_buy_potential,
    COUNT(DISTINCT ss.ss_ticket_number) AS order_cnt,
    SUM(ss.ss_net_paid) AS total_sales,
    SUM(ss.ss_ext_discount_amt) AS total_discount,
    SUM(inv_agg.total_qty) AS total_inventory,
    AVG(p.p_cost) AS avg_promo_cost,
    MAX(ss.ss_net_profit) AS max_profit
FROM store_sales_yr ss
JOIN store s
  ON ss.ss_store_sk = s.s_store_sk
JOIN item i
  ON ss.ss_item_sk = i.i_item_sk
JOIN customer c
  ON ss.ss_customer_sk = c.c_customer_sk
JOIN customer_demographics cd
  ON ss.ss_cdemo_sk = cd.cd_demo_sk
JOIN household_demographics hd
  ON ss.ss_hdemo_sk = hd.hd_demo_sk
JOIN income_band ib
  ON hd.hd_income_band_sk = ib.ib_income_band_sk
JOIN promotion p
  ON ss.ss_promo_sk = p.p_promo_sk
JOIN catalog_returns_yr cr
  ON ss.ss_item_sk = cr.cr_item_sk
 AND ss.ss_sold_date_sk = cr.cr_returned_date_sk
JOIN catalog_page cp
  ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
JOIN call_center cc
  ON cr.cr_call_center_sk = cc.cc_call_center_sk
JOIN ship_mode sm
  ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
JOIN inv_agg
  ON ss.ss_item_sk = inv_agg.inv_item_sk
 AND ss.ss_sold_date_sk = inv_agg.inv_date_sk
JOIN intersect_stores ist
  ON ss.ss_store_sk = ist.ss_store_sk
WHERE
    s.s_tax_percentage = 0.04
    AND i.i_brand = 'BrandX'
    AND p.p_channel_event = 'N'
    AND ib.ib_upper_bound > 50000
    AND sm.sm_type = 'AIR'
    AND ss.ss_net_paid > (SELECT max_cost FROM scalar_max_promo)
GROUP BY
    s.s_store_name,
    s.s_tax_percentage,
    i.i_brand,
    cd.cd_gender,
    hd.hd_buy_potential
ORDER BY total_sales DESC
LIMIT 100
