WITH joined_data AS (
  SELECT
    d.d_year,
    cc.cc_name,
    cs.cs_net_paid_inc_tax,
    ss.ss_net_paid,
    cr.cr_net_loss,
    wr.wr_net_loss,
    inv.inv_quantity_on_hand,
    ws.web_site_id
  FROM tpcds.date_dim d
  LEFT JOIN tpcds.store_sales ss
    ON ss.ss_sold_date_sk = d.d_date_sk
  LEFT JOIN tpcds.catalog_sales cs
    ON cs.cs_sold_date_sk = d.d_date_sk
  LEFT JOIN tpcds.call_center cc
    ON cs.cs_call_center_sk = cc.cc_call_center_sk
  LEFT JOIN tpcds.catalog_page cp
    ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
  LEFT JOIN tpcds.ship_mode sm
    ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
  LEFT JOIN tpcds.catalog_returns cr
    ON cr.cr_order_number = cs.cs_order_number
    AND cr.cr_returned_date_sk = d.d_date_sk
  LEFT JOIN tpcds.inventory inv
    ON inv.inv_date_sk = d.d_date_sk
  LEFT JOIN tpcds.web_returns wr
    ON wr.wr_returned_date_sk = d.d_date_sk
  LEFT JOIN tpcds.web_site ws
    ON ws.web_open_date_sk = d.d_date_sk
),
agg_by_year_cc AS (
  SELECT
    d_year,
    cc_name,
    SUM(cs_net_paid_inc_tax) AS sum_sales,
    SUM(ss_net_paid) AS sum_store_sales,
    SUM(cr_net_loss) AS sum_catalog_returns_loss,
    SUM(wr_net_loss) AS sum_web_returns_loss,
    SUM(inv_quantity_on_hand) AS sum_inventory_qty,
    COUNT(DISTINCT web_site_id) AS cnt_web_sites
  FROM joined_data
  WHERE d_year BETWEEN 1998 AND 2000
    AND cc_name IS NOT NULL
    AND cs_net_paid_inc_tax > 0
    AND ss_net_paid > 0
  GROUP BY d_year, cc_name
)
SELECT
  d_year,
  AVG(sum_sales) AS avg_sales_per_cc,
  AVG(sum_store_sales) AS avg_store_sales_per_cc,
  AVG(sum_catalog_returns_loss) AS avg_catalog_loss_per_cc
FROM agg_by_year_cc
WHERE cnt_web_sites >= 1
GROUP BY d_year
ORDER BY d_year DESC
