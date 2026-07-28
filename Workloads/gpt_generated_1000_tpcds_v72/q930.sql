WITH raw AS (
    SELECT
        s.s_store_name,
        s.s_state,
        w.w_warehouse_name,
        w.w_city,
        cp.cp_department,
        cp.cp_type,
        t.t_hour,
        sm.sm_type,
        r_cr.r_reason_desc AS catalog_return_reason,
        r_wr.r_reason_desc AS web_return_reason,
        cs.cs_order_number,
        cs.cs_net_profit AS catalog_net_profit,
        ss.ss_net_profit AS store_net_profit,
        ws.ws_net_profit AS web_net_profit,
        cr.cr_net_loss AS catalog_return_loss,
        wr.wr_net_loss AS web_return_loss,
        cs.cs_ext_sales_price AS catalog_ext_sales,
        ws.ws_ext_sales_price AS web_ext_sales,
        -- scalar subquery per catalog page
        (SELECT MAX(cs2.cs_net_profit)
         FROM catalog_sales cs2
         WHERE cs2.cs_catalog_page_sk = cp.cp_catalog_page_sk) AS max_page_profit
    FROM catalog_sales cs
    JOIN catalog_page cp               ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN call_center cc                ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN ship_mode sm                  ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w                   ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN time_dim t                    ON cs.cs_sold_time_sk = t.t_time_sk
    JOIN household_demographics hd1   ON cs.cs_bill_hdemo_sk = hd1.hd_demo_sk
    JOIN customer_address ca1         ON cs.cs_bill_addr_sk = ca1.ca_address_sk
    LEFT JOIN catalog_returns cr      ON cr.cr_order_number = cs.cs_order_number
    LEFT JOIN reason r_cr             ON cr.cr_reason_sk = r_cr.r_reason_sk
    JOIN store_sales ss               ON ss.ss_sold_time_sk = t.t_time_sk
    JOIN store s                      ON ss.ss_store_sk = s.s_store_sk
    JOIN web_sales ws                 ON ws.ws_sold_time_sk = t.t_time_sk
    LEFT JOIN web_returns wr          ON wr.wr_order_number = ws.ws_order_number
    LEFT JOIN reason r_wr             ON wr.wr_reason_sk = r_wr.r_reason_sk
    JOIN inventory inv                ON inv.inv_warehouse_sk = w.w_warehouse_sk
    JOIN web_page wp                  ON ws.ws_web_page_sk = wp.wp_web_page_sk
    WHERE cc.cc_state = 'CA'
      AND cp.cp_type = 'Online'
      AND s.s_state = 'TX'
      AND w.w_city = 'Seattle'
      AND t.t_hour BETWEEN 9 AND 17
      AND EXISTS (
          SELECT 1 FROM catalog_returns cr2
          WHERE cr2.cr_order_number = cs.cs_order_number
            AND cr2.cr_net_loss > 1000
      )
),
grouped AS (
    SELECT
        s_store_name,
        s_state,
        w_warehouse_name,
        w_city,
        cp_department,
        cp_type,
        t_hour,
        sm_type,
        max_page_profit,
        COUNT(DISTINCT cs_order_number)                                   AS distinct_orders,
        SUM(catalog_net_profit)                                            AS total_catalog_profit,
        SUM(store_net_profit)                                              AS total_store_profit,
        SUM(web_net_profit)                                                AS total_web_profit,
        SUM(CASE WHEN catalog_return_reason IS NOT NULL THEN catalog_return_loss ELSE 0 END) AS total_catalog_return_loss,
        SUM(CASE WHEN web_return_reason IS NOT NULL THEN web_return_loss ELSE 0 END)         AS total_web_return_loss,
        AVG(CASE WHEN sm_type = 'AIR' THEN catalog_ext_sales END)         AS avg_air_catalog_sales
    FROM raw
    GROUP BY
        s_store_name,
        s_state,
        w_warehouse_name,
        w_city,
        cp_department,
        cp_type,
        t_hour,
        sm_type,
        max_page_profit
)
SELECT
    g.*,
    SUM(g.total_catalog_profit + g.total_store_profit + g.total_web_profit) OVER (PARTITION BY g.s_state) AS state_total_profit
FROM grouped g
ORDER BY state_total_profit DESC
LIMIT 100
