WITH combined AS (
   SELECT
     ss.ss_ticket_number,
     ss.ss_sold_date_sk,
     d.d_year,
     s.s_store_sk,
     s.s_store_name,
     s.s_state,
     i.i_item_sk,
     i.i_category,
     c.c_customer_sk,
     c.c_customer_id,
     cd.cd_gender,
     hd.hd_income_band_sk,
     ca.ca_city,
     p.p_promo_id,
     cc.cc_name,
     cp.cp_department,
     cr.cr_return_quantity,
     sr.sr_return_quantity,
     inv.inv_quantity_on_hand,
     ib.ib_lower_bound,
     ib.ib_upper_bound,
     ws.web_name
   FROM store_sales ss
   JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
   JOIN store s ON ss.ss_store_sk = s.s_store_sk
   JOIN item i ON ss.ss_item_sk = i.i_item_sk
   JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
   JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
   JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
   JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
   LEFT JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
   LEFT JOIN catalog_sales cs ON cs.cs_sold_date_sk = d.d_date_sk
        AND cs.cs_bill_customer_sk = c.c_customer_sk
        AND cs.cs_item_sk = i.i_item_sk
   LEFT JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
   LEFT JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
   LEFT JOIN catalog_returns cr ON cs.cs_order_number = cr.cr_order_number
   LEFT JOIN store_returns sr ON ss.ss_ticket_number = sr.sr_ticket_number
   LEFT JOIN inventory inv ON inv.inv_date_sk = d.d_date_sk AND inv.inv_item_sk = i.i_item_sk
   LEFT JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
   LEFT JOIN web_site ws ON ws.web_open_date_sk = d.d_date_sk
   WHERE d.d_year = 2001
     AND s.s_state = 'TX'
     AND i.i_category = 'Books'
),
 top_customers_union AS (
   SELECT c.c_customer_id
   FROM store_sales ss
   JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
   WHERE ss.ss_quantity > 0
   UNION ALL
   SELECT c.c_customer_id
   FROM catalog_sales cs
   JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
   WHERE cs.cs_quantity > 0
 )
SELECT
  comb.c_customer_id,
  comb.s_store_name,
  comb.i_category,
  SUM(COALESCE(comb.cr_return_quantity, 0)) AS total_catalog_returns,
  SUM(COALESCE(comb.sr_return_quantity, 0)) AS total_store_returns,
  COUNT(*) AS transaction_count,
  RANK() OVER (PARTITION BY comb.s_store_sk ORDER BY SUM(COALESCE(comb.cr_return_quantity, 0) + COALESCE(comb.sr_return_quantity, 0)) DESC) AS return_rank,
  CASE WHEN SUM(COALESCE(comb.inv_quantity_on_hand,0)) > 1000 THEN 'HighStock' ELSE 'LowStock' END AS stock_level,
  (SELECT AVG(inv2.inv_quantity_on_hand) FROM inventory inv2 WHERE inv2.inv_item_sk = comb.i_item_sk) AS avg_item_stock,
  EXISTS (
    SELECT 1 FROM store_returns sr2
    WHERE sr2.sr_ticket_number = comb.ss_ticket_number
      AND sr2.sr_net_loss > 500
  ) AS heavy_loss_return,
  (SELECT COUNT(*) FROM top_customers_union u WHERE u.c_customer_id = comb.c_customer_id) AS union_occurrences
FROM combined comb
GROUP BY
  comb.c_customer_id,
  comb.s_store_name,
  comb.i_category,
  comb.s_store_sk,
  comb.i_item_sk,
  comb.ss_ticket_number
ORDER BY
  total_catalog_returns DESC,
  comb.c_customer_id
LIMIT 100
