WITH sales_aggregated AS (
  SELECT
    i.i_item_id,
    i.i_product_name,
    i.i_class,
    i.i_category,
    w.w_warehouse_name,
    s.s_store_name,
    cc.cc_name,
    r.r_reason_desc,
    SUM(cs.cs_net_paid) AS total_catalog_sales,
    SUM(cs.cs_ext_tax) AS total_catalog_tax,
    SUM(sr.sr_net_loss) AS total_store_returns_loss,
    SUM(ws.ws_net_paid) AS total_web_sales,
    SUM(cr.cr_net_loss) AS total_catalog_returns_loss,
    COUNT(DISTINCT cs.cs_order_number) AS distinct_catalog_orders,
    COUNT(DISTINCT ws.ws_order_number) AS distinct_web_orders
  FROM
    item i
    JOIN catalog_sales cs ON cs.cs_item_sk = i.i_item_sk
    JOIN catalog_returns cr ON cr.cr_item_sk = i.i_item_sk
    JOIN store_returns sr ON sr.sr_item_sk = i.i_item_sk
    JOIN web_sales ws ON ws.ws_item_sk = i.i_item_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
    JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
  WHERE
    i.i_class = 'accessories'
    AND i.i_category_id = 4
    AND w.w_zip = '74136'
    AND cc.cc_state = 'CA'
    AND cc.cc_rec_start_date >= DATE '2001-01-01'
    AND cc.cc_rec_start_date <= DATE '2001-12-31'
    AND r.r_reason_id = 'AAAAAAAAIAAAAAAA'
  GROUP BY
    i.i_item_id,
    i.i_product_name,
    i.i_class,
    i.i_category,
    w.w_warehouse_name,
    s.s_store_name,
    cc.cc_name,
    r.r_reason_desc
)
SELECT
  *,
  SUM(total_catalog_sales + total_web_sales) OVER (
    ORDER BY total_catalog_sales DESC
    ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
  ) AS cumulative_sales,
  RANK() OVER (ORDER BY total_catalog_sales + total_web_sales DESC) AS sales_rank
FROM sales_aggregated
ORDER BY sales_rank
LIMIT 100
