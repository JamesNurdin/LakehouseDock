WITH sales_with_dims AS (
   SELECT
       cs.cs_order_number,
       cs.cs_item_sk,
       cs.cs_quantity,
       cs.cs_ext_discount_amt,
       cs.cs_ext_ship_cost,
       cs.cs_net_paid,
       cs.cs_net_profit,
       cs.cs_bill_hdemo_sk,
       cs.cs_ship_hdemo_sk,
       cs.cs_bill_addr_sk,
       cs.cs_ship_addr_sk,
       cs.cs_call_center_sk,
       cs.cs_catalog_page_sk,
       cs.cs_ship_mode_sk,
       cs.cs_promo_sk,
       i.i_category,
       i.i_item_id,
       p.p_promo_id,
       p.p_channel_email,
       cc.cc_name,
       cp.cp_catalog_page_number,
       ca.ca_state,
       hd.hd_income_band_sk
   FROM tpcds.catalog_sales cs
   RIGHT OUTER JOIN tpcds.promotion p
       ON cs.cs_promo_sk = p.p_promo_sk
   LEFT JOIN tpcds.item i
       ON cs.cs_item_sk = i.i_item_sk
   LEFT JOIN tpcds.call_center cc
       ON cs.cs_call_center_sk = cc.cc_call_center_sk
   LEFT JOIN tpcds.catalog_page cp
       ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
   LEFT JOIN tpcds.ship_mode sm
       ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
   LEFT JOIN tpcds.customer_address ca
       ON cs.cs_bill_addr_sk = ca.ca_address_sk
   LEFT JOIN tpcds.household_demographics hd
       ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
),
returns_full AS (
   SELECT
       cr.cr_order_number,
       cr.cr_item_sk,
       cr.cr_return_quantity,
       cr.cr_return_amount,
       r.r_reason_desc,
       cr.cr_reason_sk
   FROM tpcds.catalog_returns cr
   FULL OUTER JOIN tpcds.reason r
       ON cr.cr_reason_sk = r.r_reason_sk
),
web_wr AS (
   SELECT
       wr.wr_order_number,
       wr.wr_item_sk,
       wr.wr_return_quantity,
       wr.wr_return_amt,
       r2.r_reason_desc AS web_reason_desc
   FROM tpcds.web_returns wr
   LEFT JOIN tpcds.reason r2
       ON wr.wr_reason_sk = r2.r_reason_sk
   LEFT JOIN tpcds.item i2
       ON wr.wr_item_sk = i2.i_item_sk
)
SELECT
   sd.p_promo_id,
   sd.cc_name,
   sd.cp_catalog_page_number,
   sd.i_category,
   SUM(sd.cs_net_paid) AS total_net_paid,
   COUNT(DISTINCT sd.cs_item_sk) AS distinct_item_count,
   SUM(DISTINCT sd.cs_ext_discount_amt) AS distinct_discount_sum,
   MAX(sd.cs_ext_ship_cost) AS max_ship_cost,
   RANK() OVER (PARTITION BY sd.p_promo_id ORDER BY SUM(sd.cs_net_paid) DESC) AS promo_rank
FROM sales_with_dims sd
LEFT JOIN returns_full rf
   ON sd.cs_order_number = rf.cr_order_number
LEFT JOIN web_wr ww
   ON sd.cs_item_sk = ww.wr_item_sk
WHERE
   sd.p_channel_email = 'N'                                 -- predicate 1
   AND sd.ca_state = 'CA'                                   -- predicate 2
   AND sd.cs_quantity > 1                                   -- predicate 3
   AND sd.cs_ext_discount_amt > 100                         -- predicate 4
   AND sd.cs_order_number NOT IN (
       SELECT cr_order_number
       FROM tpcds.catalog_returns
       WHERE cr_return_quantity > 0
   )                                                       -- anti‑semi join
   AND sd.cs_ext_ship_cost > (
       SELECT MAX(cs_ext_ship_cost)
       FROM tpcds.catalog_sales
       WHERE cs_quantity = 1
   )                                                       -- scalar subquery comparison
GROUP BY
   sd.p_promo_id,
   sd.cc_name,
   sd.cp_catalog_page_number,
   sd.i_category
HAVING
   SUM(sd.cs_net_paid) > 0
ORDER BY total_net_paid DESC
LIMIT 100
