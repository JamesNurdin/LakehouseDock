WITH per_store_ship AS (
    SELECT
        s.s_store_name,
        sm.sm_type,
        SUM(cs.cs_net_profit) AS total_profit,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        SUM(wr.wr_return_amt) AS total_returns
    FROM catalog_sales cs
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN inventory inv ON inv.inv_warehouse_sk = w.w_warehouse_sk
    JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
    JOIN store_sales ss ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN web_returns wr ON wr.wr_refunded_addr_sk = ca.ca_address_sk
    JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
    WHERE cc.cc_state = 'CA'
      AND sm.sm_type = 'AIR'
      AND w.w_state = 'TX'
      AND ca.ca_state = 'NY'
      AND cs.cs_wholesale_cost > 30.00
      AND cs.cs_ship_date_sk BETWEEN 2450870 AND 2450895
      AND ss.ss_quantity > 5
      AND inv.inv_quantity_on_hand < 100
    GROUP BY s.s_store_name, sm.sm_type
)
SELECT
    sm_type,
    AVG(total_profit) AS avg_profit,
    SUM(total_sales) AS total_sales_all,
    SUM(total_returns) AS total_returns_all
FROM per_store_ship
GROUP BY sm_type
HAVING AVG(total_profit) > 1000
ORDER BY avg_profit DESC
