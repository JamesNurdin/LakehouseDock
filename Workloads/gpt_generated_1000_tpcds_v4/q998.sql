WITH joined_data AS (
    SELECT
        s.s_store_name,
        we.web_name,
        td.t_hour,
        cs.cs_ext_sales_price,
        ss.ss_ext_sales_price,
        ws.ws_ext_sales_price,
        cs.cs_order_number,
        cs.cs_net_profit,
        ws.ws_net_paid,
        ss.ss_net_paid
    FROM catalog_sales cs
    JOIN call_center cc
        ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp
        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN warehouse w
        ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN inventory i
        ON w.w_warehouse_sk = i.inv_warehouse_sk
    JOIN time_dim td
        ON cs.cs_sold_time_sk = td.t_time_sk
    JOIN customer c
        ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN store_sales ss
        ON td.t_time_sk = ss.ss_sold_time_sk
        AND c.c_customer_sk = ss.ss_customer_sk
    JOIN store s
        ON ss.ss_store_sk = s.s_store_sk
    JOIN web_sales ws
        ON td.t_time_sk = ws.ws_sold_time_sk
        AND c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN web_site we
        ON ws.ws_web_site_sk = we.web_site_sk
    JOIN web_returns wr
        ON ws.ws_order_number = wr.wr_order_number
        AND td.t_time_sk = wr.wr_returned_time_sk
    WHERE s.s_company_id = 1
      AND s.s_rec_start_date BETWEEN DATE '2000-01-01' AND DATE '2002-12-31'
      AND cp.cp_department = 'Books'
      AND td.t_hour BETWEEN 9 AND 17
      AND cs.cs_ext_sales_price > 1000.00
      AND i.inv_quantity_on_hand > 0
)
SELECT
    s_store_name,
    web_name,
    t_hour,
    SUM(cs_ext_sales_price) AS catalog_sales_total,
    SUM(ss_ext_sales_price) AS store_sales_total,
    SUM(ws_ext_sales_price) AS web_sales_total,
    SUM(cs_ext_sales_price) + SUM(ss_ext_sales_price) + SUM(ws_ext_sales_price) AS total_sales,
    COUNT(DISTINCT cs_order_number) AS catalog_orders,
    AVG(cs_net_profit) AS avg_catalog_profit,
    MIN(ws_net_paid) AS min_web_net_paid,
    MAX(ss_net_paid) AS max_store_net_paid
FROM joined_data
GROUP BY s_store_name, web_name, t_hour
ORDER BY total_sales DESC
LIMIT 100
