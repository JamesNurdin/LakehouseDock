WITH joined AS (
  SELECT
    d.d_date_sk,
    d.d_year,
    cc.cc_call_center_sk,
    cc.cc_call_center_id,
    cc.cc_state,
    ss.ss_ext_sales_price AS store_sales_amount,
    cs.cs_ext_sales_price AS catalog_sales_amount,
    cs.cs_net_profit,
    c.c_customer_sk,
    c.c_customer_id,
    ca.ca_state,
    i.i_category,
    w.w_warehouse_sk,
    w.w_warehouse_id,
    wp.wp_web_page_id,
    ws.web_site_id,
    cr.cr_return_amount,
    cs.cs_order_number
  FROM date_dim d
  FULL OUTER JOIN call_center cc
    ON cc.cc_closed_date_sk = d.d_date_sk
  JOIN store_sales ss
    ON ss.ss_sold_date_sk = d.d_date_sk
  JOIN item i
    ON ss.ss_item_sk = i.i_item_sk
  JOIN customer c
    ON ss.ss_customer_sk = c.c_customer_sk
  JOIN customer_address ca
    ON ss.ss_addr_sk = ca.ca_address_sk
  JOIN catalog_sales cs
    ON cs.cs_sold_date_sk = d.d_date_sk
    AND cs.cs_item_sk = i.i_item_sk
    AND cs.cs_bill_customer_sk = c.c_customer_sk
    AND cs.cs_bill_addr_sk = ca.ca_address_sk
  JOIN warehouse w
    ON cs.cs_warehouse_sk = w.w_warehouse_sk
  JOIN web_page wp
    ON wp.wp_customer_sk = c.c_customer_sk
    AND wp.wp_creation_date_sk = d.d_date_sk
  JOIN web_site ws
    ON ws.web_open_date_sk = d.d_date_sk
  JOIN catalog_returns cr
    ON cr.cr_order_number = cs.cs_order_number
    AND cr.cr_item_sk = i.i_item_sk
    AND cr.cr_refunded_customer_sk = c.c_customer_sk
    AND cr.cr_refunded_addr_sk = ca.ca_address_sk
    AND cr.cr_call_center_sk = cc.cc_call_center_sk
    AND cr.cr_warehouse_sk = w.w_warehouse_sk
    AND cr.cr_returned_date_sk = d.d_date_sk
  WHERE d.d_year = 2001
    AND i.i_category = 'Sports'
    AND cc.cc_state = 'CA'
    AND EXISTS (
      SELECT 1 FROM catalog_returns crx
      WHERE crx.cr_order_number = cs.cs_order_number
        AND crx.cr_return_amount > 0
    )
),
agg AS (
  SELECT
    cc_call_center_id,
    cc_call_center_sk,
    SUM(store_sales_amount) AS total_store_sales,
    SUM(catalog_sales_amount) AS total_catalog_sales,
    AVG(cs_net_profit) AS avg_net_profit,
    COUNT(DISTINCT c_customer_id) AS unique_customers,
    (SELECT COUNT(*) FROM catalog_returns cr2 WHERE cr2.cr_call_center_sk = cc_call_center_sk) AS total_returns_for_center
  FROM joined
  GROUP BY cc_call_center_id, cc_call_center_sk
  HAVING SUM(store_sales_amount) > 100000
),
agg_excl AS (
  SELECT
    cc_call_center_id,
    cc_call_center_sk,
    SUM(store_sales_amount) AS total_store_sales,
    SUM(catalog_sales_amount) AS total_catalog_sales,
    AVG(cs_net_profit) AS avg_net_profit,
    COUNT(DISTINCT c_customer_id) AS unique_customers,
    (SELECT COUNT(*) FROM catalog_returns cr2 WHERE cr2.cr_call_center_sk = cc_call_center_sk) AS total_returns_for_center
  FROM joined
  WHERE cr_return_amount > 5000
  GROUP BY cc_call_center_id, cc_call_center_sk
)
SELECT *
FROM agg
EXCEPT
SELECT *
FROM agg_excl
ORDER BY total_store_sales DESC
LIMIT 100
