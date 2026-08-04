WITH
  /* Store sales aggregated per store and day */
  store_data AS (
    SELECT
      s.s_store_id,
      d.d_date_sk,
      SUM(ss.ss_ext_sales_price) AS store_sales_amount,
      COUNT(DISTINCT ss.ss_ticket_number) AS store_txn_cnt
    FROM store_sales ss
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    WHERE p.p_channel_demo = 'N'
      AND cd.cd_dep_count = 2
      AND d.d_year = 2001
    GROUP BY s.s_store_id, d.d_date_sk
  ),

  /* Web sales sampled and aggregated per web page and day */
  web_data AS (
    SELECT
      ws.ws_web_page_sk,
      d.d_date_sk,
      SUM(ws.ws_ext_sales_price) AS web_sales_amount,
      COUNT(DISTINCT ws.ws_order_number) AS web_order_cnt
    FROM web_sales ws
    TABLESAMPLE BERNOULLI (10)
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    JOIN customer_address ca ON ws.ws_bill_addr_sk = ca.ca_address_sk
    WHERE p.p_channel_demo = 'N'
      AND cd.cd_dep_employed_count = 3
      AND d.d_year = 2001
    GROUP BY ws.ws_web_page_sk, d.d_date_sk
  ),

  /* Customers that bought both in store and web in 2001 */
  customer_overlap AS (
    SELECT DISTINCT ss.ss_customer_sk AS cust_sk
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
    INTERSECT
    SELECT DISTINCT ws.ws_bill_customer_sk AS cust_sk
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
  ),

  /* Catalog return totals per department and day */
  catalog_data AS (
    SELECT
      cp.cp_department,
      d.d_date_sk,
      SUM(cr.cr_return_amount) AS total_return_amount,
      COUNT(DISTINCT cr.cr_order_number) AS return_cnt
    FROM catalog_returns cr
    JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    WHERE cc.cc_division_name = 'anti'
      AND d.d_year = 2001
    GROUP BY cp.cp_department, d.d_date_sk
  ),

  /* Inventory levels per warehouse and day */
  inventory_data AS (
    SELECT
      w.w_warehouse_id,
      d.d_date_sk,
      SUM(i.inv_quantity_on_hand) AS total_qty
    FROM inventory i
    JOIN date_dim d ON i.inv_date_sk = d.d_date_sk
    JOIN warehouse w ON i.inv_warehouse_sk = w.w_warehouse_sk
    WHERE d.d_year = 2001
    GROUP BY w.w_warehouse_id, d.d_date_sk
  ),

  /* Store returns aggregated per store and day */
  store_returns_data AS (
    SELECT
      sr.sr_store_sk,
      d.d_date_sk,
      SUM(sr.sr_return_amt) AS total_return_amt,
      COUNT(*) AS return_rows
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
    GROUP BY sr.sr_store_sk, d.d_date_sk
  ),

  /* Web returns aggregated per web page and day */
  web_returns_data AS (
    SELECT
      wr.wr_web_page_sk,
      d.d_date_sk,
      SUM(wr.wr_return_amt) AS total_web_return,
      COUNT(*) AS web_return_rows
    FROM web_returns wr
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
    GROUP BY wr.wr_web_page_sk, d.d_date_sk
  ),

  /* Full outer join of store and web returns on the return date */
  returns_full AS (
    SELECT
      COALESCE(sr.sr_store_sk, -1) AS sr_store_sk,
      COALESCE(wr.wr_web_page_sk, -1) AS wr_web_page_sk,
      COALESCE(sr.d_date_sk, wr.d_date_sk) AS d_date_sk,
      COALESCE(sr.total_return_amt, 0) AS store_return_amt,
      COALESCE(wr.total_web_return, 0) AS web_return_amt
    FROM (
      SELECT sr.sr_store_sk, sr.d_date_sk, sr.total_return_amt
      FROM store_returns_data sr
    ) sr
    FULL OUTER JOIN (
      SELECT wr.wr_web_page_sk, wr.d_date_sk, wr.total_web_return
      FROM web_returns_data wr
    ) wr
      ON sr.d_date_sk = wr.d_date_sk
  ),

  /* Count of overlapping customers */
  overlap_cnt AS (
    SELECT COUNT(*) AS cust_overlap_cnt
    FROM customer_overlap
  )

SELECT
  d.d_date,
  sd.s_store_id,
  sd.store_sales_amount,
  wd.web_sales_amount,
  cd.total_return_amount,
  id.total_qty,
  rf.store_return_amt,
  rf.web_return_amt,
  oc.cust_overlap_cnt
FROM date_dim d
LEFT JOIN store_data sd ON sd.d_date_sk = d.d_date_sk
LEFT JOIN web_data wd ON wd.d_date_sk = d.d_date_sk
LEFT JOIN catalog_data cd ON cd.d_date_sk = d.d_date_sk
LEFT JOIN inventory_data id ON id.d_date_sk = d.d_date_sk
LEFT JOIN returns_full rf ON rf.d_date_sk = d.d_date_sk
CROSS JOIN overlap_cnt oc
WHERE d.d_year = 2001
ORDER BY d.d_date ASC
LIMIT 100
