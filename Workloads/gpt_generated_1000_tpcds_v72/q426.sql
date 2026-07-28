WITH
  catalog_sales_agg AS (
    SELECT
      d_sold.d_year AS year,
      cp.cp_department AS department,
      w.w_warehouse_name AS warehouse,
      cd.cd_gender AS gender,
      s.s_store_name AS store_name,
      wp.wp_type AS page_type,
      r.r_reason_desc AS return_reason,
      ws.web_name AS website_name,
      SUM(cs.cs_ext_sales_price) AS total_sales,
      SUM(cs.cs_net_profit) AS total_profit,
      COUNT(DISTINCT cs.cs_order_number) AS orders,
      COUNT(DISTINCT wr.wr_order_number) AS return_orders
    FROM catalog_sales cs
    JOIN date_dim d_sold      ON cs.cs_sold_date_sk = d_sold.d_date_sk
    JOIN date_dim d_ship      ON cs.cs_ship_date_sk = d_ship.d_date_sk
    JOIN time_dim t_sold      ON cs.cs_sold_time_sk = t_sold.t_time_sk
    JOIN catalog_page cp      ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN warehouse w          ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN store s        ON s.s_closed_date_sk = d_sold.d_date_sk
    LEFT JOIN inventory inv  ON inv.inv_date_sk = d_sold.d_date_sk
    LEFT JOIN warehouse w_inv ON inv.inv_warehouse_sk = w_inv.w_warehouse_sk
    LEFT JOIN web_returns wr ON wr.wr_returned_date_sk = d_sold.d_date_sk
    LEFT JOIN reason r       ON wr.wr_reason_sk = r.r_reason_sk
    LEFT JOIN web_page wp    ON wr.wr_web_page_sk = wp.wp_web_page_sk
    LEFT JOIN web_site ws    ON ws.web_open_date_sk = d_sold.d_date_sk
    WHERE cp.cp_catalog_number = 7
      AND d_sold.d_year = 2001
    GROUP BY
      d_sold.d_year,
      cp.cp_department,
      w.w_warehouse_name,
      cd.cd_gender,
      s.s_store_name,
      wp.wp_type,
      r.r_reason_desc,
      ws.web_name
  ),
  store_sales_agg AS (
    SELECT
      d_sold.d_year AS year,
      s.s_store_name AS department,
      w.w_warehouse_name AS warehouse,
      cd.cd_gender AS gender,
      s.s_store_name AS store_name,
      CAST(NULL AS varchar) AS page_type,
      CAST(NULL AS varchar) AS return_reason,
      CAST(NULL AS varchar) AS website_name,
      SUM(ss.ss_ext_sales_price) AS total_sales,
      SUM(ss.ss_net_profit) AS total_profit,
      COUNT(DISTINCT ss.ss_ticket_number) AS orders,
      0 AS return_orders
    FROM store_sales ss
    JOIN date_dim d_sold      ON ss.ss_sold_date_sk = d_sold.d_date_sk
    JOIN time_dim t_sold      ON ss.ss_sold_time_sk = t_sold.t_time_sk
    JOIN store s              ON ss.ss_store_sk = s.s_store_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN inventory inv   ON inv.inv_date_sk = d_sold.d_date_sk
    LEFT JOIN warehouse w     ON inv.inv_warehouse_sk = w.w_warehouse_sk
    WHERE s.s_state = 'CA'
    GROUP BY
      d_sold.d_year,
      s.s_store_name,
      w.w_warehouse_name,
      cd.cd_gender,
      s.s_store_name
  )
SELECT * FROM catalog_sales_agg
UNION ALL
SELECT * FROM store_sales_agg
ORDER BY year, department, warehouse, gender
