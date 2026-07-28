WITH base AS (
  SELECT
    i.i_item_id,
    i.i_product_name,
    d.d_year,
    ws.ws_net_profit,
    sr.sr_net_loss,
    cr.cr_net_loss,
    i.i_current_price,
    cc.cc_gmt_offset,
    r.r_reason_desc,
    wp.wp_type
  FROM tpcds.date_dim d
  LEFT JOIN tpcds.web_sales ws
    ON ws.ws_sold_date_sk = d.d_date_sk
  LEFT JOIN tpcds.item i
    ON i.i_item_sk = ws.ws_item_sk
  LEFT JOIN tpcds.store_returns sr
    ON sr.sr_returned_date_sk = d.d_date_sk
  LEFT JOIN tpcds.catalog_returns cr
    ON cr.cr_returned_date_sk = d.d_date_sk
  LEFT JOIN tpcds.inventory inv
    ON inv.inv_date_sk = d.d_date_sk
  LEFT JOIN tpcds.reason r
    ON r.r_reason_sk = sr.sr_reason_sk
  LEFT JOIN tpcds.ship_mode sm
    ON sm.sm_ship_mode_sk = ws.ws_ship_mode_sk
  LEFT JOIN tpcds.warehouse w
    ON w.w_warehouse_sk = ws.ws_warehouse_sk
  LEFT JOIN tpcds.call_center cc
    ON cc.cc_closed_date_sk = d.d_date_sk
  LEFT JOIN tpcds.catalog_page cp
    ON cp.cp_end_date_sk = d.d_date_sk
  LEFT JOIN tpcds.web_page wp
    ON wp.wp_creation_date_sk = d.d_date_sk
  LEFT JOIN tpcds.web_site we
    ON we.web_open_date_sk = d.d_date_sk
  LEFT JOIN tpcds.customer_address ca
    ON ca.ca_address_sk = sr.sr_addr_sk
  LEFT JOIN tpcds.customer_demographics cd
    ON cd.cd_demo_sk = sr.sr_cdemo_sk
  -- additional joins to satisfy catalog_returns foreign‑key rules
  LEFT JOIN tpcds.call_center cc2
    ON cc2.cc_call_center_sk = cr.cr_call_center_sk
  LEFT JOIN tpcds.catalog_page cp2
    ON cp2.cp_catalog_page_sk = cr.cr_catalog_page_sk
  LEFT JOIN tpcds.ship_mode sm2
    ON sm2.sm_ship_mode_sk = cr.cr_ship_mode_sk
  LEFT JOIN tpcds.warehouse w2
    ON w2.w_warehouse_sk = cr.cr_warehouse_sk
  LEFT JOIN tpcds.reason r2
    ON r2.r_reason_sk = cr.cr_reason_sk
),
agg AS (
  SELECT
    i_item_id,
    i_product_name,
    d_year,
    SUM(ws_net_profit)        AS total_net_profit,
    SUM(sr_net_loss)          AS total_store_loss,
    SUM(cr_net_loss)          AS total_catalog_loss,
    SUM(ws_net_profit) - (SUM(sr_net_loss) + SUM(cr_net_loss)) AS total_combined_profit
  FROM base
  WHERE d_year BETWEEN 1998 AND 2002
    AND i_current_price > 20
    AND cc_gmt_offset IS NOT NULL
    AND r_reason_desc IS NOT NULL
    AND wp_type = 'Home'
  GROUP BY i_item_id, i_product_name, d_year
)
SELECT
  i_item_id,
  i_product_name,
  d_year,
  total_net_profit,
  total_store_loss,
  total_catalog_loss,
  total_combined_profit,
  CASE
    WHEN total_net_profit > (total_store_loss + total_catalog_loss) THEN 'Profit'
    ELSE 'Loss'
  END AS profit_status,
  ROW_NUMBER() OVER (PARTITION BY d_year ORDER BY total_combined_profit DESC) AS rank_in_year,
  SUM(total_combined_profit) OVER (PARTITION BY d_year) AS year_total_profit
FROM agg
ORDER BY total_combined_profit DESC
LIMIT 100
