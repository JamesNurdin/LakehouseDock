WITH base AS (
   SELECT
     i.i_item_id,
     i.i_category,
     cc.cc_name,
     cc.cc_market_manager,
     d_sold.d_year,
     SUM(ss.ss_ext_sales_price) AS store_sales_total,
     SUM(ss.ss_net_profit) AS store_profit_total,
     SUM(cs.cs_ext_sales_price) AS catalog_sales_total,
     SUM(cs.cs_net_profit) AS catalog_profit_total,
     SUM(cr.cr_return_amount) AS returns_total,
     SUM(cr.cr_net_loss) AS returns_loss_total,
     SUM(inv.inv_quantity_on_hand) AS inventory_on_hand,
     COUNT(DISTINCT wp.wp_web_page_id) AS web_pages_created
   FROM store_sales ss
   INNER JOIN date_dim d_sold
       ON ss.ss_sold_date_sk = d_sold.d_date_sk
   INNER JOIN time_dim t_ss
       ON ss.ss_sold_time_sk = t_ss.t_time_sk
   INNER JOIN item i
       ON ss.ss_item_sk = i.i_item_sk
   INNER JOIN customer c_ss
       ON ss.ss_customer_sk = c_ss.c_customer_sk
   INNER JOIN household_demographics hd_ss
       ON ss.ss_hdemo_sk = hd_ss.hd_demo_sk
   INNER JOIN catalog_sales cs
       ON cs.cs_item_sk = i.i_item_sk
      AND cs.cs_sold_date_sk = d_sold.d_date_sk
   INNER JOIN call_center cc
       ON cs.cs_call_center_sk = cc.cc_call_center_sk
   INNER JOIN catalog_page cp
       ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
   INNER JOIN ship_mode sm
       ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
   INNER JOIN warehouse w
       ON cs.cs_warehouse_sk = w.w_warehouse_sk
   LEFT JOIN catalog_returns cr
       ON cr.cr_order_number = cs.cs_order_number
      AND cr.cr_item_sk = i.i_item_sk
   LEFT JOIN reason r
       ON cr.cr_reason_sk = r.r_reason_sk
   LEFT JOIN inventory inv
       ON inv.inv_item_sk = i.i_item_sk
      AND inv.inv_date_sk = d_sold.d_date_sk
   LEFT JOIN web_page wp
       ON wp.wp_customer_sk = c_ss.c_customer_sk
      AND wp.wp_creation_date_sk = d_sold.d_date_sk
   WHERE d_sold.d_date >= DATE '2001-01-01'
     AND d_sold.d_date < DATE '2002-01-01'
     AND cc.cc_market_manager = 'Matthew Clifton'
     AND wp.wp_type = 'welcome'
   GROUP BY i.i_item_id, i.i_category, cc.cc_name, cc.cc_market_manager, d_sold.d_year
)
SELECT
  d_year,
  COUNT(DISTINCT i_item_id) AS distinct_items,
  SUM(store_sales_total) AS total_store_sales,
  SUM(catalog_sales_total) AS total_catalog_sales,
  SUM(returns_total) AS total_returns,
  SUM(store_sales_total + catalog_sales_total - returns_total) AS net_sales_year,
  AVG(CASE WHEN (store_profit_total + catalog_profit_total - returns_loss_total) > 0 THEN 1.0 ELSE 0.0 END) AS profitable_item_ratio,
  CASE
    WHEN SUM(store_profit_total + catalog_profit_total - returns_loss_total) > 0 THEN 'Yearly Profitable'
    ELSE 'Yearly Unprofitable'
  END AS year_profitability
FROM base
GROUP BY d_year
HAVING SUM(store_sales_total + catalog_sales_total - returns_total) > 50000
ORDER BY net_sales_year DESC
LIMIT 100
