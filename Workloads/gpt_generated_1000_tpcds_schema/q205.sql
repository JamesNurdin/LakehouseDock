WITH
  store_sales_agg AS (
    SELECT
      ss_item_sk,
      ss_store_sk,
      ss_customer_sk,
      ss_ticket_number,
      SUM(ss_net_paid) AS total_net_paid,
      AVG(ss_ext_discount_amt) AS avg_discount,
      COUNT(*) AS sales_cnt
    FROM store_sales
    WHERE ss_quantity > 0
    GROUP BY ss_item_sk, ss_store_sk, ss_customer_sk, ss_ticket_number
  ),
  catalog_sales_agg AS (
    SELECT
      cs_item_sk,
      cs_warehouse_sk,
      cs_bill_customer_sk,
      cs_ship_mode_sk,
      SUM(cs_net_paid) AS total_cs_net_paid,
      AVG(cs_ext_discount_amt) AS avg_cs_discount,
      COUNT(*) AS cs_cnt
    FROM catalog_sales
    WHERE cs_quantity > 0
    GROUP BY cs_item_sk, cs_warehouse_sk, cs_bill_customer_sk, cs_ship_mode_sk
  ),
  excluded_items AS (
    SELECT i_item_sk
    FROM item
    WHERE i_category = 'Electronics'
    EXCEPT
    SELECT inv_item_sk
    FROM inventory
    WHERE inv_quantity_on_hand = 0
  )
SELECT
  i.i_item_id,
  s.s_store_name,
  w.w_warehouse_name,
  sm.sm_type AS ship_mode_type,
  cd.cd_credit_rating,
  hd.hd_buy_potential,
  ib.ib_lower_bound,
  ss_agg.total_net_paid,
  cs_agg.total_cs_net_paid,
  ss_agg.sales_cnt,
  cs_agg.cs_cnt,
  sr.sr_return_tax,
  wr.wr_return_tax,
  wp.wp_url
FROM store_sales_agg ss_agg
FULL OUTER JOIN catalog_sales_agg cs_agg
  ON ss_agg.ss_item_sk = cs_agg.cs_item_sk
JOIN item i
  ON COALESCE(ss_agg.ss_item_sk, cs_agg.cs_item_sk) = i.i_item_sk
JOIN store s
  ON ss_agg.ss_store_sk = s.s_store_sk
JOIN warehouse w
  ON cs_agg.cs_warehouse_sk = w.w_warehouse_sk
JOIN ship_mode sm
  ON cs_agg.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN customer c
  ON COALESCE(ss_agg.ss_customer_sk, cs_agg.cs_bill_customer_sk) = c.c_customer_sk
JOIN customer_demographics cd
  ON c.c_current_cdemo_sk = cd.cd_demo_sk
JOIN household_demographics hd
  ON c.c_current_hdemo_sk = hd.hd_demo_sk
JOIN income_band ib
  ON hd.hd_income_band_sk = ib.ib_income_band_sk
LEFT JOIN store_returns sr
  ON sr.sr_item_sk = ss_agg.ss_item_sk
 AND sr.sr_ticket_number = ss_agg.ss_ticket_number
LEFT JOIN reason r
  ON sr.sr_reason_sk = r.r_reason_sk
LEFT JOIN web_returns wr
  ON wr.wr_item_sk = i.i_item_sk
LEFT JOIN web_page wp
  ON wr.wr_web_page_sk = wp.wp_web_page_sk
WHERE
  i.i_category = 'Electronics'
  AND s.s_state = 'CA'
  AND cd.cd_credit_rating = 'Good'
  AND hd.hd_income_band_sk = 10
  AND EXISTS (SELECT 1 FROM excluded_items ei WHERE ei.i_item_sk = i.i_item_sk)
  AND ss_agg.total_net_paid > 1000
  AND cs_agg.total_cs_net_paid > 500
ORDER BY total_net_paid DESC
LIMIT 100
