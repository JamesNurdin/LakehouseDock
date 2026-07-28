WITH aggregated AS (
  SELECT
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    s.s_store_name,
    w.w_warehouse_name,
    r.r_reason_desc,
    COUNT(DISTINCT cr.cr_order_number) AS returns_cnt,
    SUM(cr.cr_return_amount) AS total_return_amount,
    SUM(cs.cs_net_paid) AS total_sales_paid,
    AVG(cs.cs_ext_sales_price) AS avg_sales_price,
    MIN(cr.cr_returned_date_sk) AS first_return_date_sk,
    MAX(cr.cr_returned_date_sk) AS last_return_date_sk
  FROM catalog_returns cr
  JOIN catalog_sales cs
    ON cr.cr_order_number = cs.cs_order_number
   AND cr.cr_item_sk = cs.cs_item_sk
  JOIN item i
    ON cs.cs_item_sk = i.i_item_sk
  JOIN customer c
    ON cs.cs_bill_customer_sk = c.c_customer_sk
  JOIN customer_address ca
    ON cs.cs_bill_addr_sk = ca.ca_address_sk
  JOIN reason r
    ON cr.cr_reason_sk = r.r_reason_sk
  JOIN warehouse w
    ON cs.cs_warehouse_sk = w.w_warehouse_sk
  JOIN store_sales ss
    ON ss.ss_item_sk = i.i_item_sk
  JOIN store s
    ON ss.ss_store_sk = s.s_store_sk
  JOIN web_page wp
    ON wp.wp_customer_sk = c.c_customer_sk
  WHERE c.c_first_name IN ('Tonya', 'Michael')
    AND i.i_current_price > 500
    AND cr.cr_fee > 50
    AND cs.cs_quantity > 5
    AND ss.ss_ext_tax > 10
  GROUP BY
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    s.s_store_name,
    w.w_warehouse_name,
    r.r_reason_desc
)
SELECT
  *,
  ROW_NUMBER() OVER (PARTITION BY w_warehouse_name ORDER BY total_return_amount DESC) AS warehouse_return_rank
FROM aggregated
ORDER BY total_return_amount DESC
LIMIT 100
