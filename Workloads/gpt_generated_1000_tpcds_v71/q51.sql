WITH sales_agg AS (
    SELECT
        d.d_year,
        cp.cp_department,
        cs.cs_order_number AS order_number,
        SUM(cs.cs_ext_sales_price) AS order_sales,
        SUM(cs.cs_quantity) AS order_quantity,
        MAX(t.t_hour) AS max_sold_hour,
        CASE WHEN SUM(cs.cs_ext_sales_price) > 5000 THEN 'High' ELSE 'Low' END AS sales_category
    FROM tpcds.date_dim d
    JOIN tpcds.catalog_page cp
        ON cp.cp_start_date_sk = d.d_date_sk
    JOIN tpcds.catalog_sales cs
        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
       AND cs.cs_sold_date_sk = d.d_date_sk
    JOIN tpcds.time_dim t
        ON t.t_time_sk = cs.cs_sold_time_sk
    WHERE d.d_year BETWEEN 1999 AND 2001
      AND cp.cp_department = 'Electronics'
      AND cs.cs_quantity > 30
    GROUP BY d.d_year, cp.cp_department, cs.cs_order_number
)
SELECT
    sa.d_year,
    sa.cp_department,
    sa.sales_category,
    COUNT(DISTINCT ws.ws_order_number) AS distinct_web_orders,
    SUM(sa.order_sales) AS total_catalog_sales,
    SUM(cr.cr_return_amount) AS total_return_amount,
    SUM(i.inv_quantity_on_hand) AS total_inventory,
    AVG(CASE WHEN cr.cr_return_amount > 0 THEN cr.cr_return_amount ELSE sa.order_sales END) AS avg_amount
FROM sales_agg sa
JOIN tpcds.catalog_returns cr
    ON cr.cr_order_number = sa.order_number
JOIN tpcds.ship_mode sm
    ON sm.sm_ship_mode_sk = cr.cr_ship_mode_sk
JOIN tpcds.warehouse w
    ON w.w_warehouse_sk = cr.cr_warehouse_sk
JOIN tpcds.inventory i
    ON i.inv_warehouse_sk = w.w_warehouse_sk
JOIN tpcds.date_dim d2
    ON i.inv_date_sk = d2.d_date_sk
   AND d2.d_year = sa.d_year
JOIN tpcds.store_sales ss
    ON ss.ss_sold_date_sk = d2.d_date_sk
JOIN tpcds.store_returns sr
    ON sr.sr_ticket_number = ss.ss_ticket_number
JOIN tpcds.web_sales ws
    ON ws.ws_sold_date_sk = d2.d_date_sk
JOIN tpcds.web_page wp
    ON wp.wp_web_page_sk = ws.ws_web_page_sk
JOIN tpcds.web_site we
    ON we.web_site_sk = ws.ws_web_site_sk
JOIN tpcds.customer_address ca
    ON ca.ca_address_sk = ss.ss_addr_sk
JOIN tpcds.customer_demographics cd
    ON cd.cd_demo_sk = ss.ss_cdemo_sk
WHERE sm.sm_carrier = 'UPS'
  AND w.w_state = 'CA'
  AND i.inv_quantity_on_hand > 100
  AND we.web_state = 'CA'
  AND sr.sr_return_quantity > 0
GROUP BY sa.d_year, sa.cp_department, sa.sales_category
HAVING SUM(sa.order_sales) > 10000
ORDER BY sa.d_year, total_catalog_sales DESC
