WITH sales_2001 AS (
    SELECT 
        ca.ca_state,
        d.d_year AS sales_year,
        SUM(ws.ws_ext_sales_price) AS total_sales
    FROM tpcds.web_sales ws
    JOIN tpcds.date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN tpcds.customer_address ca ON ws.ws_bill_addr_sk = ca.ca_address_sk
    JOIN tpcds.warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    WHERE d.d_year = 2001
      AND EXISTS (
          SELECT 1
          FROM tpcds.warehouse w2
          WHERE w2.w_warehouse_sk = ws.ws_warehouse_sk
            AND w2.w_warehouse_sq_ft > 300000
      )
    GROUP BY ca.ca_state, d.d_year
),
sales_2002 AS (
    SELECT 
        ca.ca_state,
        d.d_year AS sales_year,
        SUM(ws.ws_ext_sales_price) AS total_sales
    FROM tpcds.web_sales ws
    JOIN tpcds.date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN tpcds.customer_address ca ON ws.ws_bill_addr_sk = ca.ca_address_sk
    JOIN tpcds.warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    WHERE d.d_year = 2002
      AND EXISTS (
          SELECT 1
          FROM tpcds.warehouse w2
          WHERE w2.w_warehouse_sk = ws.ws_warehouse_sk
            AND w2.w_warehouse_sq_ft > 300000
      )
    GROUP BY ca.ca_state, d.d_year
)
SELECT * FROM sales_2001
UNION ALL
SELECT * FROM sales_2002
ORDER BY total_sales DESC, sales_year
OFFSET 0
LIMIT 100
