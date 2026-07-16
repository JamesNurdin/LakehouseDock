SELECT
    s.s_store_id,
    s.s_city,
    s.s_state,
    w.w_warehouse_name,
    w.w_city AS warehouse_city,
    d_ret.d_year AS return_year,
    COUNT(*) AS total_returns,
    SUM(cr.cr_net_loss) AS total_net_loss,
    SUM(cr.cr_return_amount) AS total_return_amount,
    AVG(cr.cr_return_quantity) AS avg_return_qty,
    COUNT(DISTINCT cr.cr_refunded_customer_sk) AS distinct_refunded_customers,
    COUNT(DISTINCT cr.cr_returning_customer_sk) AS distinct_returning_customers,
    MIN(d_cust_sales.d_date) AS earliest_first_sales_date,
    MAX(d_cust_shipto.d_date) AS latest_first_shipto_date,
    MAX(d_ret.d_date) AS store_closed_date,
    MIN(c_ref.c_birth_year) AS youngest_refunded_customer_birth_year,
    MAX(c_ret.c_birth_year) AS oldest_returning_customer_birth_year
FROM catalog_returns cr
JOIN date_dim d_ret
  ON cr.cr_returned_date_sk = d_ret.d_date_sk
JOIN customer c_ref
  ON cr.cr_refunded_customer_sk = c_ref.c_customer_sk
JOIN customer c_ret
  ON cr.cr_returning_customer_sk = c_ret.c_customer_sk
JOIN warehouse w
  ON cr.cr_warehouse_sk = w.w_warehouse_sk
JOIN store s
  ON s.s_closed_date_sk = d_ret.d_date_sk
JOIN date_dim d_cust_sales
  ON c_ref.c_first_sales_date_sk = d_cust_sales.d_date_sk
JOIN date_dim d_cust_shipto
  ON c_ret.c_first_shipto_date_sk = d_cust_shipto.d_date_sk
GROUP BY
    s.s_store_id,
    s.s_city,
    s.s_state,
    w.w_warehouse_name,
    w.w_city,
    d_ret.d_year
ORDER BY total_net_loss DESC
LIMIT 100
