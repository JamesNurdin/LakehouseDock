WITH
  sales_data AS (
    SELECT
      i.i_brand AS brand,
      'sale' AS txn_type,
      CAST(NULL AS varchar) AS store_id,
      SUM(cs.cs_net_paid) AS total_amount,
      SUM(COALESCE(wr.wr_return_amt, 0)) AS web_return_amount,
      COUNT(*) AS txn_count
    FROM catalog_sales cs
      JOIN time_dim t_sales ON cs.cs_sold_time_sk = t_sales.t_time_sk
      JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
      JOIN item i ON cs.cs_item_sk = i.i_item_sk
      JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
      JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk
                         AND inv.inv_warehouse_sk = w.w_warehouse_sk
      JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
      JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
      JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
      JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
      LEFT JOIN web_page wp ON wp.wp_customer_sk = c.c_customer_sk
      LEFT JOIN web_returns wr ON wr.wr_item_sk = i.i_item_sk
                                AND wr.wr_returned_time_sk = t_sales.t_time_sk
    WHERE i.i_brand = 'brandnameless #5'
      AND ca.ca_state = 'TX'
      AND t_sales.t_hour BETWEEN 9 AND 17
    GROUP BY i.i_brand
  ),
  returns_data AS (
    SELECT
      i.i_brand AS brand,
      'store_return' AS txn_type,
      s.s_store_id AS store_id,
      SUM(sr.sr_net_loss * -1) AS total_amount,
      SUM(COALESCE(wr.wr_return_amt, 0)) AS web_return_amount,
      COUNT(*) AS txn_count
    FROM store_returns sr
      JOIN item i ON sr.sr_item_sk = i.i_item_sk
      JOIN time_dim t_return ON sr.sr_return_time_sk = t_return.t_time_sk
      JOIN store s ON sr.sr_store_sk = s.s_store_sk
      JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
      JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
      JOIN customer_demographics cd ON sr.sr_cdemo_sk = cd.cd_demo_sk
      JOIN household_demographics hd ON sr.sr_hdemo_sk = hd.hd_demo_sk
      JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk
      JOIN warehouse w ON inv.inv_warehouse_sk = w.w_warehouse_sk
      LEFT JOIN web_returns wr ON wr.wr_item_sk = i.i_item_sk
                               AND wr.wr_returned_time_sk = t_return.t_time_sk
      LEFT JOIN web_page wp ON wp.wp_customer_sk = c.c_customer_sk
    WHERE i.i_brand = 'brandnameless #5'
      AND ca.ca_state = 'TX'
      AND s.s_state = 'TX'
      AND t_return.t_hour BETWEEN 9 AND 17
    GROUP BY i.i_brand, s.s_store_id
  ),
  combined AS (
    SELECT brand, txn_type, store_id, total_amount, web_return_amount, txn_count
    FROM sales_data
    UNION ALL
    SELECT brand, txn_type, store_id, total_amount, web_return_amount, txn_count
    FROM returns_data
  )
SELECT
  brand,
  txn_type,
  store_id,
  total_amount,
  web_return_amount,
  txn_count,
  RANK() OVER (PARTITION BY txn_type ORDER BY total_amount DESC) AS rank_by_type,
  SUM(total_amount) OVER (PARTITION BY brand) AS brand_cumulative_amount,
  CASE WHEN total_amount > 10000 THEN 'high' ELSE 'low' END AS amount_category
FROM combined
ORDER BY rank_by_type, total_amount DESC
LIMIT 100
