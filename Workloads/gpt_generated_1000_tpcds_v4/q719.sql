WITH sales_agg AS (
    SELECT
        w.w_county,
        ca.ca_city,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        AVG(ws.ws_wholesale_cost) AS avg_wholesale_cost,
        COUNT(*) AS order_cnt
    FROM tpcds.web_sales ws
    JOIN tpcds.customer_address ca
        ON ws.ws_bill_addr_sk = ca.ca_address_sk
    JOIN tpcds.warehouse w
        ON ws.ws_warehouse_sk = w.w_warehouse_sk
    WHERE ws.ws_net_paid_inc_tax > 500
      AND ws.ws_quantity >= 2
      AND w.w_country = 'United States'
    GROUP BY w.w_county, ca.ca_city
)
SELECT
    w_county,
    ca_city,
    total_sales,
    avg_wholesale_cost,
    order_cnt
FROM sales_agg
WHERE total_sales > 2000
  AND avg_wholesale_cost > 30
  AND order_cnt >= 5
ORDER BY total_sales DESC
LIMIT 100
