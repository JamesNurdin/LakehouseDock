WITH sales_data AS (
  SELECT
    cs.cs_quantity,
    cs.cs_ext_sales_price,
    cs.cs_ext_discount_amt,
    cs.cs_ext_ship_cost,
    cs.cs_net_paid,
    cs.cs_order_number,
    cs.cs_bill_customer_sk,
    d_sold.d_year,
    d_sold.d_month_seq,
    w.w_warehouse_name,
    sm.sm_ship_mode_id,
    i.i_category
  FROM catalog_sales cs
  JOIN date_dim d_sold ON cs.cs_sold_date_sk = d_sold.d_date_sk
  JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
  JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
  JOIN item i ON cs.cs_item_sk = i.i_item_sk
  JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
  JOIN date_dim d_promo_start ON p.p_start_date_sk = d_promo_start.d_date_sk
  JOIN date_dim d_promo_end ON p.p_end_date_sk = d_promo_end.d_date_sk
  WHERE d_sold.d_date >= DATE '2001-01-01'
    AND d_sold.d_date <= DATE '2001-12-31'
    AND p.p_discount_active = 'Y'
    AND d_sold.d_date BETWEEN d_promo_start.d_date AND d_promo_end.d_date
)
SELECT
  d_year,
  d_month_seq,
  w_warehouse_name,
  sm_ship_mode_id,
  i_category,
  SUM(cs_ext_sales_price) AS total_sales,
  SUM(cs_ext_discount_amt) AS total_discount,
  SUM(cs_ext_ship_cost) AS total_shipping_cost,
  SUM(cs_net_paid) AS total_net_paid,
  SUM(cs_quantity) AS total_quantity,
  COUNT(DISTINCT cs_order_number) AS distinct_orders,
  COUNT(DISTINCT cs_bill_customer_sk) AS distinct_customers,
  ROUND(SUM(cs_ext_discount_amt) / NULLIF(SUM(cs_ext_sales_price), 0), 4) AS avg_discount_rate,
  ROUND(AVG(cs_ext_ship_cost), 2) AS avg_shipping_cost
FROM sales_data
GROUP BY d_year, d_month_seq, w_warehouse_name, sm_ship_mode_id, i_category
ORDER BY d_year, d_month_seq, total_sales DESC
LIMIT 50
