WITH sales_base AS (
  SELECT
    cs.cs_sold_date_sk,
    cs.cs_bill_customer_sk,
    c.c_first_name,
    c.c_last_name,
    ca.ca_state,
    hd.hd_income_band_sk,
    p.p_promo_name,
    sm.sm_type,
    t.t_time_sk,
    t.t_hour,
    wp.wp_max_ad_count,
    SUM(cs.cs_net_paid) AS total_net_paid,
    SUM(cs.cs_quantity) AS total_qty,
    COUNT(DISTINCT cs.cs_order_number) AS distinct_orders
  FROM catalog_sales cs
  JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
  JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
  JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
  JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
  JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
  JOIN time_dim t ON cs.cs_sold_time_sk = t.t_time_sk
  JOIN web_page wp ON wp.wp_customer_sk = c.c_customer_sk
  WHERE cs.cs_net_paid > 1000
    AND ca.ca_state IN ('CA','TX')
    AND p.p_discount_active = 'Y'
    AND t.t_hour BETWEEN 8 AND 20
    AND wp.wp_max_ad_count >= 1
  GROUP BY cs.cs_sold_date_sk,
           cs.cs_bill_customer_sk,
           c.c_first_name,
           c.c_last_name,
           ca.ca_state,
           hd.hd_income_band_sk,
           p.p_promo_name,
           sm.sm_type,
           t.t_time_sk,
           t.t_hour,
           wp.wp_max_ad_count
),
returns_agg AS (
  SELECT
    sb.*, 
    SUM(r.sr_return_amt) AS total_return_amount
  FROM sales_base sb
  JOIN store_returns r ON r.sr_return_time_sk = sb.t_time_sk
  WHERE r.sr_return_amt > 0
  GROUP BY sb.cs_sold_date_sk,
           sb.cs_bill_customer_sk,
           sb.c_first_name,
           sb.c_last_name,
           sb.ca_state,
           sb.hd_income_band_sk,
           sb.p_promo_name,
           sb.sm_type,
           sb.t_hour,
           sb.total_net_paid,
           sb.total_qty,
           sb.distinct_orders,
           sb.t_time_sk,
           sb.wp_max_ad_count
)
SELECT
  ra.cs_sold_date_sk,
  ra.cs_bill_customer_sk,
  ra.c_first_name,
  ra.c_last_name,
  ra.ca_state,
  ra.hd_income_band_sk,
  ra.p_promo_name,
  ra.sm_type,
  ra.t_hour,
  ra.total_net_paid,
  ra.total_qty,
  ra.distinct_orders,
  ra.total_return_amount,
  AVG(ra.total_net_paid) OVER (PARTITION BY ra.ca_state) AS avg_state_net_paid
FROM returns_agg ra
WHERE ra.total_return_amount > 500
ORDER BY ra.total_net_paid DESC
LIMIT 100
