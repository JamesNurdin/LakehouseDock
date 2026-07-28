WITH
  inv_summary AS (
    SELECT
      inv.inv_date_sk,
      inv.inv_warehouse_sk,
      SUM(inv.inv_quantity_on_hand) AS total_on_hand
    FROM inventory inv
    GROUP BY inv.inv_date_sk, inv.inv_warehouse_sk
  ),
  web_agg AS (
    SELECT
      d.d_date AS wk_date,
      COUNT(*) AS web_page_cnt,
      AVG(wp.wp_link_count) AS avg_links
    FROM web_page wp
    JOIN date_dim d ON wp.wp_creation_date_sk = d.d_date_sk
    WHERE wp.wp_type = 'article'
    GROUP BY d.d_date
  ),
  catalog_agg AS (
    SELECT
      d.d_date AS cat_date,
      COUNT(*) AS catalog_return_cnt,
      SUM(cr.cr_return_amount) AS catalog_return_amount
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    WHERE cc.cc_state = 'CA'
    GROUP BY d.d_date
  ),
  sales_returns_agg AS (
    SELECT
      s.s_store_id,
      d.d_date,
      d.d_date_sk,
      d.d_year,
      SUM(ss.ss_ext_sales_price) AS total_sales,
      SUM(ss.ss_net_profit) AS total_profit,
      SUM(COALESCE(sr.sr_net_loss, 0)) AS total_returns_loss,
      SUM(ss.ss_quantity) AS total_quantity,
      SUM(ss.ss_ext_discount_amt) AS total_discount,
      SUM(ss.ss_ext_tax) AS total_tax,
      SUM(ss.ss_wholesale_cost) AS total_wholesale_cost,
      SUM(ss.ss_list_price) AS total_list_price,
      SUM(ss.ss_sales_price) AS total_sales_price,
      SUM(ss.ss_ext_sales_price) - SUM(COALESCE(sr.sr_net_loss, 0)) AS net_revenue
    FROM store_sales ss
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    LEFT JOIN store_returns sr
      ON ss.ss_ticket_number = sr.sr_ticket_number
     AND sr.sr_store_sk = s.s_store_sk
    WHERE d.d_date BETWEEN DATE '2001-01-01' AND DATE '2001-12-31'
      AND s.s_state = 'CA'
      AND ib.ib_lower_bound >= 100000
      AND ca.ca_country = 'United States'
    GROUP BY s.s_store_id, d.d_date, d.d_date_sk, d.d_year
  )
SELECT
  sra.s_store_id,
  sra.d_date,
  sra.total_sales,
  sra.total_profit,
  sra.total_returns_loss,
  sra.net_revenue,
  COALESCE(inv.total_on_hand, 0) AS inventory_on_hand,
  COALESCE(wa.web_page_cnt, 0) AS web_page_cnt,
  COALESCE(wa.avg_links, 0) AS avg_web_links,
  COALESCE(ca.catalog_return_cnt, 0) AS catalog_return_cnt,
  COALESCE(ca.catalog_return_amount, 0) AS catalog_return_amount,
  RANK() OVER (PARTITION BY sra.d_year ORDER BY sra.total_profit DESC) AS profit_rank_year
FROM sales_returns_agg sra
LEFT JOIN inv_summary inv ON inv.inv_date_sk = sra.d_date_sk
LEFT JOIN web_agg wa ON wa.wk_date = sra.d_date
LEFT JOIN catalog_agg ca ON ca.cat_date = sra.d_date
ORDER BY sra.d_year, profit_rank_year
