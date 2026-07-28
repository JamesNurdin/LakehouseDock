WITH store_sales_agg AS (
    SELECT
        ss_store_sk,
        ss_sold_date_sk,
        ss_cdemo_sk,
        ss_hdemo_sk,
        SUM(ss_net_paid) AS total_store_net_paid,
        COUNT(*) AS store_sales_cnt
    FROM tpcds.store_sales
    WHERE ss_quantity > 0
      AND ss_net_paid > 0
    GROUP BY ss_store_sk, ss_sold_date_sk, ss_cdemo_sk, ss_hdemo_sk
)
SELECT
    d_store.d_year,
    w.w_warehouse_name,
    cc.cc_name,
    cp.cp_type,
    r.r_reason_desc,
    ws.web_manager,
    SUM(sa.total_store_net_paid) AS agg_store_net,
    SUM(cs.cs_ext_sales_price) AS agg_catalog_sales,
    SUM(cr.cr_return_amount) AS agg_catalog_returns,
    SUM(wr.wr_return_amt) AS agg_web_returns
FROM store_sales_agg sa
JOIN tpcds.date_dim d_store
  ON sa.ss_sold_date_sk = d_store.d_date_sk
JOIN tpcds.catalog_sales cs
  ON cs.cs_sold_date_sk = d_store.d_date_sk
JOIN tpcds.catalog_returns cr
  ON cr.cr_order_number = cs.cs_order_number
  AND cr.cr_returned_date_sk = d_store.d_date_sk
JOIN tpcds.web_returns wr
  ON wr.wr_returned_date_sk = d_store.d_date_sk
JOIN tpcds.reason r
  ON r.r_reason_sk = cr.cr_reason_sk
  AND r.r_reason_sk = wr.wr_reason_sk
JOIN tpcds.call_center cc
  ON cc.cc_call_center_sk = cs.cs_call_center_sk
JOIN tpcds.catalog_page cp
  ON cp.cp_catalog_page_sk = cs.cs_catalog_page_sk
JOIN tpcds.ship_mode sm
  ON sm.sm_ship_mode_sk = cs.cs_ship_mode_sk
JOIN tpcds.warehouse w
  ON w.w_warehouse_sk = cs.cs_warehouse_sk
JOIN tpcds.customer_demographics cd
  ON cd.cd_demo_sk = sa.ss_cdemo_sk
JOIN tpcds.household_demographics hd
  ON hd.hd_demo_sk = sa.ss_hdemo_sk
JOIN tpcds.web_site ws
  ON ws.web_open_date_sk = d_store.d_date_sk
WHERE d_store.d_year = 2002
  AND cc.cc_state = 'CA'
  AND cp.cp_type = 'M'
  AND ws.web_manager = 'Charles Parker'
  AND r.r_reason_desc LIKE '%damaged%'
  AND EXISTS (
      SELECT 1 FROM tpcds.warehouse w2
      WHERE w2.w_city = 'NEW YORK'
        AND w2.w_warehouse_sk = cs.cs_warehouse_sk
  )
GROUP BY
    d_store.d_year,
    w.w_warehouse_name,
    cc.cc_name,
    cp.cp_type,
    r.r_reason_desc,
    ws.web_manager
ORDER BY agg_store_net DESC
LIMIT 100
