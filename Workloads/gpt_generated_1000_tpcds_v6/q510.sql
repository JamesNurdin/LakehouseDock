WITH sales_agg AS (
    SELECT
        cs_warehouse_sk,
        cs_bill_addr_sk,
        cs_ship_addr_sk,
        cs_sold_time_sk,
        SUM(cs_net_profit) AS total_net_profit,
        AVG(cs_ext_discount_amt) AS avg_discount,
        COUNT(*) AS order_cnt
    FROM catalog_sales
    WHERE cs_wholesale_cost > 20
      AND cs_ext_ship_cost < 5000
      AND cs_quantity >= 1
    GROUP BY cs_warehouse_sk, cs_bill_addr_sk, cs_ship_addr_sk, cs_sold_time_sk
)
SELECT
    w.w_warehouse_name,
    t.t_sub_shift,
    SUM(sa.total_net_profit) AS sum_net_profit,
    AVG(sa.avg_discount) AS avg_discount,
    SUM(sa.order_cnt) AS total_orders
FROM sales_agg sa
JOIN time_dim t
    ON sa.cs_sold_time_sk = t.t_time_sk
JOIN warehouse w
    ON sa.cs_warehouse_sk = w.w_warehouse_sk
JOIN customer_address ca_bill
    ON sa.cs_bill_addr_sk = ca_bill.ca_address_sk
JOIN customer_address ca_ship
    ON sa.cs_ship_addr_sk = ca_ship.ca_address_sk
WHERE t.t_sub_shift = 'morning'
  AND t.t_hour BETWEEN 8 AND 12
  AND ca_bill.ca_state = 'TX'
  AND ca_ship.ca_state = 'CA'
GROUP BY w.w_warehouse_name, t.t_sub_shift
ORDER BY sum_net_profit DESC
LIMIT 100
