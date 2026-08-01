WITH
 cat_sales AS (
     SELECT
         cs.cs_order_number AS order_number,
         cs.cs_ext_sales_price AS sales_amount,
         d.d_year,
         w.w_warehouse_name,
         cd.cd_gender AS gender,
         cp.cp_department AS dept
     FROM catalog_sales cs
     JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
     JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
     JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
     JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
     WHERE d.d_year BETWEEN 2000 AND 2002
 ),
 web_sales_cte AS (
     SELECT
         ws.ws_order_number AS order_number,
         ws.ws_ext_sales_price AS sales_amount,
         d.d_year,
         w.w_warehouse_name,
         cd.cd_gender AS gender,
         NULL AS dept
     FROM web_sales ws
     JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
     JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
     JOIN customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
     WHERE d.d_year BETWEEN 2000 AND 2002
 ),
 returns_cte AS (
     SELECT DISTINCT wr.wr_order_number
     FROM web_returns wr
     JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
     JOIN customer_demographics cd ON wr.wr_refunded_cdemo_sk = cd.cd_demo_sk
     WHERE d.d_year BETWEEN 2000 AND 2002
 ),
 inventory_cte AS (
     SELECT i.inv_item_sk, i.inv_quantity_on_hand, d.d_year, w.w_warehouse_name
     FROM inventory i
     JOIN date_dim d ON i.inv_date_sk = d.d_date_sk
     JOIN warehouse w ON i.inv_warehouse_sk = w.w_warehouse_sk
     WHERE d.d_year BETWEEN 2000 AND 2002
 ),
 sales_union AS (
     SELECT order_number, sales_amount, d_year, w_warehouse_name, gender, dept
     FROM cat_sales
     UNION
     SELECT order_number, sales_amount, d_year, w_warehouse_name, gender, dept
     FROM web_sales_cte
 ),
 sales_without_returns AS (
     SELECT *
     FROM sales_union su
     EXCEPT
     SELECT su2.order_number, su2.sales_amount, su2.d_year, su2.w_warehouse_name, su2.gender, su2.dept
     FROM sales_union su2
     JOIN returns_cte r ON su2.order_number = r.wr_order_number
 ),
 final_agg AS (
     SELECT
         d_year,
         w_warehouse_name,
         COUNT(DISTINCT order_number) AS orders_cnt,
         SUM(sales_amount) AS total_sales,
         SUM(sales_amount) / NULLIF(COUNT(DISTINCT order_number), 0) AS avg_sales_per_order
     FROM sales_without_returns
     GROUP BY d_year, w_warehouse_name
 )
 SELECT
     d_year,
     w_warehouse_name,
     orders_cnt,
     total_sales,
     avg_sales_per_order,
     SUM(total_sales) OVER (PARTITION BY d_year ORDER BY total_sales DESC ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_sales,
     RANK() OVER (PARTITION BY d_year ORDER BY total_sales DESC) AS sales_rank,
     (SELECT COUNT(DISTINCT cd_demo_sk) FROM customer_demographics) AS total_demo_cnt
 FROM final_agg
 ORDER BY d_year, total_sales DESC
 LIMIT 100
