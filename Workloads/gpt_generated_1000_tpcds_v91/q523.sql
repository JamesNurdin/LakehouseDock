/*
  goal: Compute, for each state, the count of top‑selling cities (the city with the highest profit in that state), the total net profit, and the average net paid (including tax) across qualifying sales. The query filters on warehouse attributes, sales amounts, and recent web pages, uses a semi‑join via EXISTS, excludes a set of warehouses with EXCEPT, applies a window function to pick the top city per state, and returns the results ordered by profit.
*/
WITH excluded_warehouses AS (
    SELECT w_warehouse_sk
    FROM warehouse
    WHERE w_suite_number = 'Suite 0'
    EXCEPT
    SELECT w_warehouse_sk
    FROM warehouse
    WHERE w_zip LIKE '7%'
),

sales_by_warehouse_pre AS (
    SELECT 
        w.w_state,
        w.w_city,
        SUM(ws.ws_net_profit) AS total_net_profit,
        AVG(ws.ws_net_paid_inc_tax) AS avg_net_paid_inc_tax,
        COUNT(*) AS sales_count,
        SUM(ws.ws_ext_wholesale_cost) AS total_wholesale_cost
    FROM web_sales ws
    JOIN warehouse w
        ON ws.ws_warehouse_sk = w.w_warehouse_sk
    WHERE w.w_warehouse_sk NOT IN (SELECT w_warehouse_sk FROM excluded_warehouses)
      AND w.w_state NOT IN ('CA', 'TX')
      AND w.w_zip BETWEEN '30000' AND '60000'
      AND ws.ws_net_paid_inc_tax > 1000
      AND ws.ws_ext_wholesale_cost < 3000
      AND EXISTS (
          SELECT 1
          FROM web_page wp
          WHERE wp.wp_web_page_sk = ws.ws_web_page_sk
            AND wp.wp_rec_end_date >= DATE '2000-01-01'
            AND wp.wp_rec_end_date <= DATE '2002-12-31'
            AND wp.wp_link_count >= 10
      )
    GROUP BY w.w_state, w.w_city
),

sales_by_warehouse AS (
    SELECT 
        w_state,
        w_city,
        total_net_profit,
        avg_net_paid_inc_tax,
        sales_count,
        total_wholesale_cost,
        ROW_NUMBER() OVER (PARTITION BY w_state ORDER BY total_net_profit DESC) AS rn_state_city
    FROM sales_by_warehouse_pre
),

final_agg AS (
    SELECT 
        w_state,
        COUNT(*) AS num_cities,
        SUM(total_net_profit) AS state_total_profit,
        AVG(avg_net_paid_inc_tax) AS state_avg_paid_inc_tax
    FROM sales_by_warehouse
    WHERE rn_state_city = 1
    GROUP BY w_state
)
SELECT 
    f.w_state,
    f.num_cities,
    f.state_total_profit,
    f.state_avg_paid_inc_tax
FROM final_agg f
ORDER BY f.state_total_profit DESC
LIMIT 100
