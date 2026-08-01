WITH
    cat_sales_sample AS (
        SELECT *
        FROM tpcds.catalog_sales
        TABLESAMPLE BERNOULLI (5)
    ),
    distinct_stores AS (
        SELECT DISTINCT s.s_store_sk, s.s_store_name, s.s_state
        FROM tpcds.store s
        WHERE s.s_state = 'TX'
    )
SELECT
    d_sales.d_year,
    cc.cc_name AS call_center_name,
    w.w_warehouse_name,
    ds.s_store_name,
    cs.cs_order_number,
    cs.cs_net_paid,
    inv.inv_quantity_on_hand,
    r.r_reason_desc AS store_return_reason,
    t_sales.t_hour AS sale_hour,
    ROW_NUMBER() OVER (PARTITION BY w.w_warehouse_sk ORDER BY cs.cs_net_paid DESC) AS warehouse_sales_rank,
    RANK() OVER (PARTITION BY d_sales.d_year ORDER BY inv.inv_quantity_on_hand DESC) AS inventory_year_rank,
    CASE WHEN cs.cs_net_paid > 1000 THEN 'High' ELSE 'Normal' END AS net_paid_category,
    (SELECT COUNT(*) FROM tpcds.web_returns) AS total_web_returns
FROM cat_sales_sample cs
JOIN tpcds.call_center cc
  ON cs.cs_call_center_sk = cc.cc_call_center_sk
JOIN tpcds.warehouse w
  ON cs.cs_warehouse_sk = w.w_warehouse_sk
JOIN tpcds.date_dim d_sales
  ON cs.cs_sold_date_sk = d_sales.d_date_sk
JOIN tpcds.time_dim t_sales
  ON cs.cs_sold_time_sk = t_sales.t_time_sk
JOIN tpcds.customer_address ca_common
  ON cs.cs_bill_addr_sk = ca_common.ca_address_sk
JOIN tpcds.customer_demographics cd_common
  ON cs.cs_bill_cdemo_sk = cd_common.cd_demo_sk
JOIN tpcds.inventory inv
  ON inv.inv_date_sk = d_sales.d_date_sk
 AND inv.inv_warehouse_sk = w.w_warehouse_sk
JOIN tpcds.store_returns sr
  ON sr.sr_addr_sk = ca_common.ca_address_sk
 AND sr.sr_cdemo_sk = cd_common.cd_demo_sk
JOIN distinct_stores ds
  ON sr.sr_store_sk = ds.s_store_sk
JOIN tpcds.reason r
  ON sr.sr_reason_sk = r.r_reason_sk
JOIN tpcds.date_dim d_return
  ON sr.sr_returned_date_sk = d_return.d_date_sk
JOIN tpcds.time_dim t_return
  ON sr.sr_return_time_sk = t_return.t_time_sk
JOIN tpcds.web_returns wr
  ON wr.wr_refunded_addr_sk = ca_common.ca_address_sk
 AND wr.wr_refunded_cdemo_sk = cd_common.cd_demo_sk
JOIN tpcds.date_dim d_wr
  ON wr.wr_returned_date_sk = d_wr.d_date_sk
JOIN tpcds.time_dim t_wr
  ON wr.wr_returned_time_sk = t_wr.t_time_sk
JOIN tpcds.web_page wp
  ON wr.wr_web_page_sk = wp.wp_web_page_sk
JOIN tpcds.date_dim d_wp_creation
  ON wp.wp_creation_date_sk = d_wp_creation.d_date_sk
JOIN tpcds.web_site ws
  ON ws.web_open_date_sk = d_sales.d_date_sk
WHERE
    d_sales.d_year = 2001
    AND t_sales.t_hour BETWEEN 9 AND 17
    AND cc.cc_state = 'CA'
    AND r.r_reason_id IN ('AAAAAAAAAGAAAAAAA','AAAAAAAABBAAAAAA')
    AND inv.inv_quantity_on_hand > 0
    AND cs.cs_net_paid > 500
    AND NOT EXISTS (
        SELECT 1
        FROM tpcds.store_returns sr_ex
        WHERE sr_ex.sr_customer_sk = cs.cs_bill_customer_sk
    )
ORDER BY cs.cs_net_paid DESC
LIMIT 100
