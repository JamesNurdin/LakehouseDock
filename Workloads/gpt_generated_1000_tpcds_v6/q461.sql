WITH avg_sales_price AS (
    SELECT avg(cs_sales_price) AS avg_price
    FROM catalog_sales
)
SELECT
    p.p_promo_name,
    sm.sm_type,
    td.t_meal_time,
    CASE
        WHEN SUM(cs.cs_net_paid) > SUM(ss.ss_net_paid) THEN 'Catalog greater'
        ELSE 'Store greater'
    END AS sales_comparison,
    SUM(cs.cs_net_paid)      AS catalog_net_paid,
    SUM(ss.ss_net_paid)      AS store_net_paid,
    SUM(ws.ws_net_paid)      AS web_net_paid,
    COUNT(DISTINCT cs.cs_order_number) AS distinct_orders
FROM catalog_sales cs
JOIN time_dim td                     ON cs.cs_sold_time_sk = td.t_time_sk
JOIN promotion p                     ON cs.cs_promo_sk = p.p_promo_sk
JOIN ship_mode sm                    ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN warehouse w                     ON cs.cs_warehouse_sk = w.w_warehouse_sk
JOIN customer_demographics cd_bill   ON cs.cs_bill_cdemo_sk = cd_bill.cd_demo_sk
JOIN customer_demographics cd_ship   ON cs.cs_ship_cdemo_sk = cd_ship.cd_demo_sk
JOIN catalog_returns cr              ON cr.cr_order_number = cs.cs_order_number
                                      AND cr.cr_item_sk = cs.cs_item_sk
LEFT JOIN time_dim td_cr             ON cr.cr_returned_time_sk = td_cr.t_time_sk
LEFT JOIN ship_mode sm_cr            ON cr.cr_ship_mode_sk = sm_cr.sm_ship_mode_sk
LEFT JOIN warehouse w_cr             ON cr.cr_warehouse_sk = w_cr.w_warehouse_sk
LEFT JOIN customer_demographics cd_refunded   ON cr.cr_refunded_cdemo_sk = cd_refunded.cd_demo_sk
LEFT JOIN customer_demographics cd_returning  ON cr.cr_returning_cdemo_sk = cd_returning.cd_demo_sk
JOIN store_sales ss                  ON ss.ss_sold_time_sk = td.t_time_sk
JOIN store s                         ON ss.ss_store_sk = s.s_store_sk
JOIN customer_demographics cd_ss    ON ss.ss_cdemo_sk = cd_ss.cd_demo_sk
JOIN promotion p_ss                  ON ss.ss_promo_sk = p_ss.p_promo_sk
JOIN web_sales ws                    ON ws.ws_sold_time_sk = td.t_time_sk
JOIN ship_mode sm_ws                 ON ws.ws_ship_mode_sk = sm_ws.sm_ship_mode_sk
JOIN warehouse w_ws                  ON ws.ws_warehouse_sk = w_ws.w_warehouse_sk
JOIN promotion p_ws                  ON ws.ws_promo_sk = p_ws.p_promo_sk
JOIN web_page wp                     ON ws.ws_web_page_sk = wp.wp_web_page_sk
JOIN customer_demographics cd_ws    ON ws.ws_bill_cdemo_sk = cd_ws.cd_demo_sk
WHERE cs.cs_sales_price > (SELECT avg_price FROM avg_sales_price)
  AND NOT EXISTS (
        SELECT 1
        FROM catalog_returns cr2
        WHERE cr2.cr_order_number = cs.cs_order_number
          AND cr2.cr_return_amount > 100
    )
GROUP BY p.p_promo_name, sm.sm_type, td.t_meal_time
ORDER BY catalog_net_paid DESC
LIMIT 100
