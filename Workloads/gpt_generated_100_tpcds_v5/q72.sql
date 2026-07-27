WITH sales_base AS (
    SELECT
        cp.cp_department,
        sm.sm_carrier,
        w.w_warehouse_name,
        COALESCE(wp.wp_url, 'N/A') AS web_page_url,
        cs.cs_order_number,
        cs.cs_net_paid,
        cs.cs_quantity,
        sr.sr_net_loss
    FROM catalog_sales cs
    INNER JOIN catalog_page cp
        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    INNER JOIN ship_mode sm
        ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    INNER JOIN warehouse w
        ON cs.cs_warehouse_sk = w.w_warehouse_sk
    INNER JOIN time_dim td
        ON cs.cs_sold_time_sk = td.t_time_sk
    INNER JOIN customer c
        ON cs.cs_bill_customer_sk = c.c_customer_sk
    INNER JOIN customer_demographics cd
        ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN store_returns sr
        ON sr.sr_customer_sk = c.c_customer_sk
        AND sr.sr_return_time_sk = td.t_time_sk
        AND sr.sr_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN web_page wp
        ON wp.wp_customer_sk = c.c_customer_sk
    WHERE cp.cp_department = 'Books'
      AND sm.sm_carrier = 'DIAMOND'
      AND td.t_hour BETWEEN 9 AND 17
      AND c.c_last_name = 'Curtis'
) 
SELECT
    cp_department,
    sm_carrier,
    w_warehouse_name,
    web_page_url,
    COUNT(DISTINCT cs_order_number) AS orders_count,
    SUM(cs_net_paid) AS total_sales,
    SUM(COALESCE(sr_net_loss, 0)) AS total_return_loss,
    AVG(cs_quantity) AS avg_quantity,
    CASE WHEN SUM(cs_net_paid) > 100000 THEN 'High' ELSE 'Low' END AS sales_category
FROM sales_base
GROUP BY
    cp_department,
    sm_carrier,
    w_warehouse_name,
    web_page_url
HAVING SUM(cs_net_paid) > 50000
ORDER BY total_sales DESC
LIMIT 100
