WITH joined_data AS (
    SELECT
        w.w_warehouse_name,
        w.w_city,
        cp.cp_department,
        cs.cs_order_number,
        cs.cs_ext_sales_price AS catalog_sales_amt,
        cr.cr_return_amount AS catalog_return_amt,
        ws.ws_ext_sales_price AS web_sales_amt,
        wr.wr_return_amt AS web_return_amt,
        ss.ss_ext_sales_price AS store_sales_amt,
        i.inv_quantity_on_hand
    FROM warehouse w
    JOIN catalog_sales cs
        ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN catalog_page cp
        ON cp.cp_catalog_page_sk = cs.cs_catalog_page_sk
    JOIN catalog_returns cr
        ON cr.cr_order_number = cs.cs_order_number
        AND cr.cr_item_sk = cs.cs_item_sk
        AND cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN time_dim td
        ON td.t_time_sk = cs.cs_sold_time_sk
    JOIN customer c
        ON c.c_customer_sk = cs.cs_bill_customer_sk
    JOIN store_sales ss
        ON ss.ss_sold_time_sk = td.t_time_sk
        AND ss.ss_customer_sk = c.c_customer_sk
    JOIN web_sales ws
        ON ws.ws_sold_time_sk = td.t_time_sk
        AND ws.ws_bill_customer_sk = c.c_customer_sk
        AND ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN web_returns wr
        ON wr.wr_order_number = ws.ws_order_number
        AND wr.wr_item_sk = ws.ws_item_sk
        AND wr.wr_returned_time_sk = td.t_time_sk
    JOIN inventory i
        ON i.inv_warehouse_sk = w.w_warehouse_sk
    JOIN web_site site
        ON site.web_site_sk = ws.ws_web_site_sk
    WHERE c.c_birth_country = 'PHILIPPINES'
      AND cp.cp_department = 'Electronics'
      AND w.w_city = 'Lincoln Adams'
      AND cr.cr_store_credit > 50
      AND ws.ws_quantity >= 2
)
SELECT
    w_warehouse_name,
    w_city,
    cp_department,
    COUNT(DISTINCT cs_order_number) AS num_orders,
    SUM(catalog_sales_amt) AS total_catalog_sales,
    SUM(catalog_return_amt) AS total_catalog_returns,
    SUM(web_sales_amt) AS total_web_sales,
    SUM(web_return_amt) AS total_web_returns,
    SUM(store_sales_amt) AS total_store_sales,
    AVG(inv_quantity_on_hand) AS avg_inventory_on_hand
FROM joined_data
GROUP BY w_warehouse_name, w_city, cp_department
ORDER BY total_catalog_sales DESC
LIMIT 100
