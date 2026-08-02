WITH inv_agg AS (
    SELECT inv_item_sk,
           inv_warehouse_sk,
           SUM(inv_quantity_on_hand) AS total_quantity_on_hand
    FROM inventory
    GROUP BY inv_item_sk, inv_warehouse_sk
)
SELECT
    d_sold.d_year,
    i.i_category,
    s.s_state,
    w.w_state,
    sm.sm_type,
    cp.cp_type,
    CASE WHEN cs.cs_ext_discount_amt > 0 THEN 'Discounted' ELSE 'Full Price' END AS sale_type,
    COUNT(DISTINCT cs.cs_order_number) AS order_count,
    SUM(cs.cs_net_paid) AS total_catalog_net_paid,
    SUM(ss.ss_net_paid) AS total_store_net_paid,
    SUM(wr.wr_net_loss) AS total_return_loss,
    SUM(inv_agg.total_quantity_on_hand) AS total_inventory_on_hand,
    COUNT(DISTINCT u.email_part) AS distinct_email_parts
FROM catalog_sales cs
JOIN date_dim d_sold ON cs.cs_sold_date_sk = d_sold.d_date_sk
JOIN time_dim t_sold ON cs.cs_sold_time_sk = t_sold.t_time_sk
JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
JOIN item i ON cs.cs_item_sk = i.i_item_sk
JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
JOIN household_demographics hd_bill ON cs.cs_bill_hdemo_sk = hd_bill.hd_demo_sk
JOIN customer c_bill ON cs.cs_bill_customer_sk = c_bill.c_customer_sk
CROSS JOIN UNNEST(split(c_bill.c_email_address, '@')) AS u(email_part)
JOIN store_sales ss ON ss.ss_item_sk = i.i_item_sk
    AND ss.ss_customer_sk = c_bill.c_customer_sk
    AND ss.ss_promo_sk = p.p_promo_sk
JOIN store s ON ss.ss_store_sk = s.s_store_sk
JOIN date_dim d_store_closed ON s.s_closed_date_sk = d_store_closed.d_date_sk
JOIN time_dim t_store_sold ON ss.ss_sold_time_sk = t_store_sold.t_time_sk
JOIN web_returns wr ON wr.wr_item_sk = i.i_item_sk
    AND wr.wr_refunded_customer_sk = c_bill.c_customer_sk
JOIN date_dim d_return ON wr.wr_returned_date_sk = d_return.d_date_sk
JOIN time_dim t_return ON wr.wr_returned_time_sk = t_return.t_time_sk
JOIN inv_agg ON inv_agg.inv_item_sk = i.i_item_sk
    AND inv_agg.inv_warehouse_sk = w.w_warehouse_sk
WHERE d_sold.d_year = 2001
  AND i.i_category = 'Sports'
  AND s.s_state = 'CA'
  AND w.w_state = 'CA'
  AND sm.sm_type = 'AIR'
  AND cp.cp_type = 'Standard'
GROUP BY
    d_sold.d_year,
    i.i_category,
    s.s_state,
    w.w_state,
    sm.sm_type,
    cp.cp_type,
    CASE WHEN cs.cs_ext_discount_amt > 0 THEN 'Discounted' ELSE 'Full Price' END
ORDER BY total_catalog_net_paid DESC
LIMIT 100
