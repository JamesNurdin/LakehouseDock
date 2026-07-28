WITH filtered_sales AS (
    SELECT
        cs.cs_sold_time_sk,
        cs.cs_warehouse_sk,
        cs.cs_net_paid_inc_ship,
        cs.cs_wholesale_cost,
        cs.cs_order_number,
        cs.cs_quantity,
        cs.cs_ext_sales_price,
        cs.cs_ext_discount_amt
    FROM catalog_sales cs
    WHERE cs.cs_net_paid_inc_ship > 5000
      AND cs.cs_wholesale_cost < 80
      AND cs.cs_quantity >= 1
)
SELECT
    w.w_city,
    w.w_state,
    t.t_hour,
    COUNT(DISTINCT s.cs_order_number)                     AS order_cnt,
    SUM(s.cs_net_paid_inc_ship)                         AS total_paid_inc_ship,
    AVG(s.cs_wholesale_cost)                             AS avg_wholesale_cost,
    SUM(COALESCE(i.inv_quantity_on_hand, 0))            AS total_inventory_on_hand,
    MIN(s.cs_ext_discount_amt)                          AS min_discount,
    MAX(s.cs_ext_sales_price)                           AS max_sales_price
FROM filtered_sales s
JOIN time_dim t
  ON s.cs_sold_time_sk = t.t_time_sk
JOIN warehouse w
  ON s.cs_warehouse_sk = w.w_warehouse_sk
LEFT OUTER JOIN inventory i
  ON i.inv_warehouse_sk = w.w_warehouse_sk
  AND i.inv_date_sk = 2451046
  AND i.inv_quantity_on_hand > 500
WHERE w.w_city = 'Salem'
  AND w.w_gmt_offset = -5.00
GROUP BY w.w_city, w.w_state, t.t_hour
ORDER BY total_paid_inc_ship DESC
LIMIT 100
