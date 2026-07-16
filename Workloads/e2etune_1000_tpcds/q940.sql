SELECT
    p.p_channel_email AS promo_channel_email,
    d_start.d_year AS promo_start_year,
    SUM(ss.ss_net_profit) AS total_net_profit,
    AVG(ss.ss_ext_discount_amt) AS avg_discount_amount,
    COUNT(DISTINCT ss.ss_customer_sk) AS distinct_customers,
    SUM(i.inv_quantity_on_hand) AS total_inventory_on_sale_date
FROM store_sales ss
JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
JOIN date_dim d_start ON p.p_start_date_sk = d_start.d_date_sk
JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
JOIN inventory i ON i.inv_date_sk = d.d_date_sk
JOIN warehouse w ON i.inv_warehouse_sk = w.w_warehouse_sk
WHERE p.p_discount_active = 'Y'
  AND d_start.d_year >= 2000
  AND hd.hd_vehicle_count >= 2
  AND c.c_preferred_cust_flag = 'Y'
  AND w.w_state = 'CA'
  AND p.p_channel_email IS NOT NULL
GROUP BY p.p_channel_email, d_start.d_year
HAVING SUM(ss.ss_net_profit) > 1000
ORDER BY total_net_profit DESC
LIMIT 50
