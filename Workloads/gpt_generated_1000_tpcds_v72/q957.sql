WITH
  base AS (
    SELECT
      d.d_year,
      d.d_fy_year,
      i.i_item_sk,
      i.i_category,
      i.i_brand,
      p.p_promo_sk,
      p.p_channel_catalog,
      p.p_channel_email,
      cs.cs_net_paid,
      cs.cs_net_profit,
      ss.ss_net_paid,
      ss.ss_net_profit,
      ws.ws_net_paid,
      ws.ws_net_profit,
      cr.cr_return_amount,
      cr.cr_net_loss,
      sr.sr_return_amt,
      sr.sr_net_loss,
      inv.inv_quantity_on_hand,
      w.w_state,
      r1.r_reason_desc AS catalog_return_reason,
      r2.r_reason_desc AS store_return_reason,
      cc.cc_name,
      cp.cp_department
    FROM tpcds.date_dim d
    JOIN tpcds.catalog_sales cs ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN tpcds.catalog_returns cr ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN tpcds.store_sales ss ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN tpcds.store_returns sr ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN tpcds.web_sales ws ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN tpcds.inventory inv ON inv.inv_date_sk = d.d_date_sk
    JOIN tpcds.item i ON i.i_item_sk = cs.cs_item_sk
    JOIN tpcds.promotion p ON p.p_promo_sk = cs.cs_promo_sk
    JOIN tpcds.warehouse w ON w.w_warehouse_sk = cs.cs_warehouse_sk
    JOIN tpcds.ship_mode sm ON sm.sm_ship_mode_sk = cs.cs_ship_mode_sk
    JOIN tpcds.reason r1 ON r1.r_reason_sk = cr.cr_reason_sk
    JOIN tpcds.reason r2 ON r2.r_reason_sk = sr.sr_reason_sk
    JOIN tpcds.call_center cc ON cc.cc_closed_date_sk = d.d_date_sk
    JOIN tpcds.catalog_page cp ON cp.cp_end_date_sk = d.d_date_sk
    WHERE cs.cs_quantity > 10
      AND sr.sr_ticket_number = ss.ss_ticket_number
  ),
  sub1 AS (
    SELECT
      d_year,
      i_category,
      i_brand,
      p_channel_catalog AS promo_channel,
      SUM(cs_net_paid) AS total_catalog_sales,
      SUM(ss_net_paid) AS total_store_sales,
      SUM(ws_net_paid) AS total_web_sales,
      SUM(cr_return_amount) AS total_catalog_returns,
      SUM(sr_return_amt) AS total_store_returns,
      AVG(inv_quantity_on_hand) AS avg_inventory_on_hand,
      COUNT(DISTINCT i_item_sk) AS distinct_items_sold,
      CASE WHEN SUM(cs_net_paid) > 100000 THEN 'High' ELSE 'Low' END AS sales_volume_category
    FROM base
    WHERE d_fy_year = 1918
      AND p_channel_catalog = 'N'
      AND i_brand = 'Brand#23'
      AND w_state = 'CA'
    GROUP BY d_year, i_category, i_brand, p_channel_catalog
  ),
  sub2 AS (
    SELECT
      d_year,
      i_category,
      i_brand,
      p_channel_email AS promo_channel,
      SUM(cs_net_paid) AS total_catalog_sales,
      SUM(ss_net_paid) AS total_store_sales,
      SUM(ws_net_paid) AS total_web_sales,
      SUM(cr_return_amount) AS total_catalog_returns,
      SUM(sr_return_amt) AS total_store_returns,
      AVG(inv_quantity_on_hand) AS avg_inventory_on_hand,
      COUNT(DISTINCT i_item_sk) AS distinct_items_sold,
      CASE WHEN SUM(cs_net_paid) > 100000 THEN 'High' ELSE 'Low' END AS sales_volume_category
    FROM base
    WHERE d_fy_year = 1910
      AND p_channel_email = 'Y'
      AND i_brand = 'Brand#45'
      AND w_state = 'TX'
    GROUP BY d_year, i_category, i_brand, p_channel_email
  )
SELECT
  d_year,
  i_category,
  i_brand,
  promo_channel,
  total_catalog_sales,
  total_store_sales,
  total_web_sales,
  total_catalog_returns,
  total_store_returns,
  avg_inventory_on_hand,
  distinct_items_sold,
  sales_volume_category,
  RANK() OVER (ORDER BY total_catalog_sales DESC) AS sales_rank
FROM (
  SELECT * FROM sub1
  UNION ALL
  SELECT * FROM sub2
) AS u
ORDER BY sales_rank ASC, d_year
