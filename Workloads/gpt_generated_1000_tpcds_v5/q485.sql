WITH agg AS (
    SELECT
        w.w_warehouse_id,
        w.w_state,
        t.t_hour,
        SUM(ss.ss_ext_sales_price)        AS total_sales,
        SUM(cr.cr_return_amount)           AS total_returns,
        SUM(ss.ss_net_profit)              AS total_profit,
        SUM(i.inv_quantity_on_hand)        AS total_inventory,
        COUNT(DISTINCT ss.ss_ticket_number) AS orders
    FROM catalog_returns cr
    JOIN time_dim t
      ON cr.cr_returned_time_sk = t.t_time_sk
    JOIN warehouse w
      ON cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN inventory i
      ON i.inv_warehouse_sk = w.w_warehouse_sk
    JOIN customer c
      ON cr.cr_refunded_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd
      ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca
      ON cr.cr_refunded_addr_sk = ca.ca_address_sk
    JOIN store_sales ss
      ON ss.ss_sold_time_sk = t.t_time_sk
     AND ss.ss_customer_sk = c.c_customer_sk
     AND ss.ss_cdemo_sk = cd.cd_demo_sk
     AND ss.ss_addr_sk = ca.ca_address_sk
    WHERE t.t_hour BETWEEN 9 AND 17
      AND ca.ca_state = 'CA'
      AND cd.cd_education_status = 'College'
      AND w.w_state = 'CA'
      AND i.inv_quantity_on_hand > 0
      AND ss.ss_net_profit > 0
    GROUP BY w.w_warehouse_id, w.w_state, t.t_hour
)
SELECT
    a.w_warehouse_id,
    a.w_state,
    a.t_hour,
    a.total_sales,
    a.total_returns,
    a.total_profit,
    a.total_inventory,
    a.orders,
    (SELECT MAX(total_sales) FROM agg) AS max_sales_overall
FROM agg a
WHERE a.total_profit > (
    SELECT AVG(total_profit) FROM agg
)
ORDER BY a.total_profit DESC
LIMIT 100
