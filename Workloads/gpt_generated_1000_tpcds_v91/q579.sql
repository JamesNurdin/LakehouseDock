WITH preferred_customers AS (
    SELECT c_customer_sk
    FROM customer
    WHERE c_preferred_cust_flag = 'Y'
),
high_profit_customers AS (
    SELECT cs_bill_customer_sk AS c_customer_sk
    FROM catalog_sales
    WHERE cs_net_profit > 5000
    GROUP BY cs_bill_customer_sk
),
eligible_customers AS (
    SELECT c_customer_sk
    FROM preferred_customers
    INTERSECT
    SELECT c_customer_sk
    FROM high_profit_customers
),
order_items AS (
    SELECT cs_order_number,
           array_agg(cs_item_sk) AS items_array
    FROM catalog_sales
    GROUP BY cs_order_number
    HAVING count(*) > 1
),
cross_numbers AS (
    SELECT 1 AS grp UNION ALL SELECT 2 UNION ALL SELECT 3
),
profit_summary AS (
    SELECT
        c.c_customer_sk,
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        w.w_warehouse_sk,
        w.w_warehouse_name,
        SUM(cs.cs_net_profit) AS catalog_net_profit,
        SUM(ss.ss_net_profit) AS store_net_profit,
        SUM(cs.cs_net_profit) + SUM(ss.ss_net_profit) AS total_profit,
        MAX(i.inv_quantity_on_hand) AS max_inv_quantity,
        MAX(t_cs.t_hour) AS cs_hour,
        MAX(t_ss.t_hour) AS ss_hour
    FROM eligible_customers ec
    JOIN customer c
        ON c.c_customer_sk = ec.c_customer_sk
    JOIN catalog_sales cs
        ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN store_sales ss
        ON ss.ss_customer_sk = c.c_customer_sk
    JOIN time_dim t_cs
        ON cs.cs_sold_time_sk = t_cs.t_time_sk
    JOIN time_dim t_ss
        ON ss.ss_sold_time_sk = t_ss.t_time_sk
    JOIN warehouse w
        ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN inventory i
        ON i.inv_warehouse_sk = w.w_warehouse_sk
    WHERE c.c_birth_year BETWEEN 1960 AND 1990
      AND cs.cs_net_paid > 1000.00
      AND ss.ss_quantity > 2
      AND w.w_state = 'CA'
      AND i.inv_quantity_on_hand > 500
      AND t_cs.t_hour BETWEEN 9 AND 17
      AND t_ss.t_hour BETWEEN 9 AND 17
      AND EXISTS (
          SELECT 1
          FROM store_sales ss2
          WHERE ss2.ss_customer_sk = c.c_customer_sk
            AND ss2.ss_net_paid > 2000
      )
      AND NOT EXISTS (
          SELECT 1
          FROM inventory i_low
          WHERE i_low.inv_warehouse_sk = w.w_warehouse_sk
            AND i_low.inv_quantity_on_hand < 600
      )
    GROUP BY
        c.c_customer_sk,
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        w.w_warehouse_sk,
        w.w_warehouse_name
    HAVING SUM(cs.cs_net_profit) + SUM(ss.ss_net_profit) > 5000
)
SELECT
    ps.c_customer_id,
    ps.c_first_name,
    ps.c_last_name,
    ps.w_warehouse_name,
    ps.catalog_net_profit,
    ps.store_net_profit,
    ps.total_profit,
    RANK() OVER (ORDER BY ps.total_profit DESC) AS profit_rank,
    oi.cs_order_number,
    item_unnested.item_sk,
    ps.max_inv_quantity,
    ps.cs_hour,
    ps.ss_hour,
    (SELECT avg(cs3.cs_net_profit) FROM catalog_sales cs3) AS avg_catalog_profit,
    cn.grp AS cross_grp
FROM profit_summary ps
JOIN catalog_sales cs2
    ON cs2.cs_bill_customer_sk = ps.c_customer_sk
JOIN order_items oi
    ON cs2.cs_order_number = oi.cs_order_number
CROSS JOIN UNNEST(oi.items_array) AS item_unnested(item_sk)
CROSS JOIN cross_numbers cn
ORDER BY profit_rank, ps.c_last_name
LIMIT 100
