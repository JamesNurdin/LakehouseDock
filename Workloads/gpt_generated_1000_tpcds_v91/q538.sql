(SELECT i.i_item_sk,
        d_sold.d_year,
        sm.sm_type,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        AVG(cs.cs_quantity) AS avg_qty,
        COUNT(*) AS order_cnt
 FROM catalog_sales cs
 JOIN date_dim d_sold ON cs.cs_sold_date_sk = d_sold.d_date_sk
 JOIN time_dim t ON cs.cs_sold_time_sk = t.t_time_sk
 JOIN date_dim d_ship ON cs.cs_ship_date_sk = d_ship.d_date_sk
 JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
 JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
 JOIN item i ON cs.cs_item_sk = i.i_item_sk
 JOIN date_dim d_page_start ON cp.cp_start_date_sk = d_page_start.d_date_sk
 JOIN date_dim d_page_end ON cp.cp_end_date_sk = d_page_end.d_date_sk
 WHERE d_sold.d_date = DATE '1998-01-01'
   AND d_ship.d_year = 1998
   AND i.i_category_id = 4
   AND i.i_class = 'dresses'
   AND sm.sm_type = 'AIR'
   AND cp.cp_catalog_number BETWEEN 100 AND 200
 GROUP BY ROLLUP (i.i_item_sk, d_sold.d_year, sm.sm_type)
 HAVING SUM(cs.cs_ext_sales_price) > 10000)
EXCEPT
(SELECT i.i_item_sk,
        d_sold.d_year,
        sm.sm_type,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        AVG(cs.cs_quantity) AS avg_qty,
        COUNT(*) AS order_cnt
 FROM catalog_sales cs
 JOIN date_dim d_sold ON cs.cs_sold_date_sk = d_sold.d_date_sk
 JOIN time_dim t ON cs.cs_sold_time_sk = t.t_time_sk
 JOIN date_dim d_ship ON cs.cs_ship_date_sk = d_ship.d_date_sk
 JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
 JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
 JOIN item i ON cs.cs_item_sk = i.i_item_sk
 JOIN date_dim d_page_start ON cp.cp_start_date_sk = d_page_start.d_date_sk
 JOIN date_dim d_page_end ON cp.cp_end_date_sk = d_page_end.d_date_sk
 WHERE d_sold.d_date = DATE '1998-01-01'
   AND d_ship.d_year = 1998
   AND i.i_category_id = 4
   AND i.i_class = 'dresses'
   AND sm.sm_type = 'AIR'
   AND cp.cp_catalog_number BETWEEN 100 AND 200
   AND cp.cp_department = 'HOME'
 GROUP BY ROLLUP (i.i_item_sk, d_sold.d_year, sm.sm_type)
 HAVING SUM(cs.cs_ext_sales_price) > 10000)
LIMIT 100
