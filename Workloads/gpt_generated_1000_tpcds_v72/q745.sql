WITH
  sales_agg AS (
    SELECT
      d.d_year AS year,
      i.i_item_id AS item_id,
      SUM(ws.ws_ext_sales_price) AS metric_value,
      'sales' AS metric_type
    FROM tpcds.web_sales ws
    JOIN tpcds.date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN tpcds.time_dim t ON ws.ws_sold_time_sk = t.t_time_sk
    JOIN tpcds.item i ON ws.ws_item_sk = i.i_item_sk
    JOIN tpcds.customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN tpcds.customer_address ca ON ws.ws_bill_addr_sk = ca.ca_address_sk
    JOIN tpcds.customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
    JOIN tpcds.household_demographics hd ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    JOIN tpcds.ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN tpcds.warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN tpcds.web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN tpcds.web_site we ON ws.ws_web_site_sk = we.web_site_sk
    JOIN tpcds.inventory inv ON inv.inv_date_sk = d.d_date_sk
                               AND inv.inv_item_sk = i.i_item_sk
                               AND inv.inv_warehouse_sk = w.w_warehouse_sk
    JOIN tpcds.income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN tpcds.store s ON s.s_closed_date_sk = d.d_date_sk
    GROUP BY d.d_year, i.i_item_id
  ),
  returns_agg AS (
    SELECT
      d.d_year AS year,
      i.i_item_id AS item_id,
      (SUM(cr.cr_return_amount) + COALESCE(SUM(wr.wr_net_loss), 0)) AS metric_value,
      'returns' AS metric_type
    FROM tpcds.catalog_returns cr
    JOIN tpcds.date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN tpcds.item i ON cr.cr_item_sk = i.i_item_sk
    JOIN tpcds.call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN tpcds.catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN tpcds.ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN tpcds.warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN tpcds.reason r ON cr.cr_reason_sk = r.r_reason_sk
    LEFT JOIN tpcds.web_returns wr
      ON wr.wr_item_sk = i.i_item_sk
     AND wr.wr_returned_date_sk = d.d_date_sk
    LEFT JOIN tpcds.customer c_wr_refunded ON wr.wr_refunded_customer_sk = c_wr_refunded.c_customer_sk
    LEFT JOIN tpcds.customer_address ca_wr_refunded ON wr.wr_refunded_addr_sk = ca_wr_refunded.ca_address_sk
    LEFT JOIN tpcds.customer_demographics cd_wr_refunded ON wr.wr_refunded_cdemo_sk = cd_wr_refunded.cd_demo_sk
    LEFT JOIN tpcds.household_demographics hd_wr_refunded ON wr.wr_refunded_hdemo_sk = hd_wr_refunded.hd_demo_sk
    LEFT JOIN tpcds.web_page wp_wr ON wr.wr_web_page_sk = wp_wr.wp_web_page_sk
    GROUP BY d.d_year, i.i_item_id
  ),
  combined AS (
    SELECT * FROM sales_agg
    UNION ALL
    SELECT * FROM returns_agg
  )
SELECT
  c.year,
  c.metric_type,
  AVG(c.metric_value) AS avg_metric,
  SUM(c.metric_value) AS total_metric
FROM combined c
WHERE c.year BETWEEN 1998 AND 2000
  AND c.metric_value > 0
  AND c.item_id LIKE 'A%'
GROUP BY c.year, c.metric_type
ORDER BY c.year DESC, avg_metric DESC
LIMIT 100
