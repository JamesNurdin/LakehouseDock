WITH ws_filtered AS (
    SELECT
        ws.ws_sold_date_sk,
        ws.ws_warehouse_sk,
        ws.ws_order_number,
        ws.ws_bill_customer_sk,
        ws.ws_ext_sales_price,
        ws.ws_net_paid,
        ws.ws_net_profit,
        d.d_day_name,
        d.d_quarter_name,
        w.w_warehouse_name,
        w.w_city
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    WHERE regexp_like(d.d_day_name, '(Mon|Tue|Wed|Thu|Fri)')
      AND w.w_city LIKE '%' || 'York'
      AND ws.ws_net_paid > (
          SELECT avg(ws2.ws_net_paid)
          FROM web_sales ws2
      )
),
agg_sales AS (
    SELECT
        w.w_warehouse_name,
        d.d_quarter_name,
        COUNT(DISTINCT ws.ws_order_number) AS distinct_orders,
        COUNT(DISTINCT ws.ws_bill_customer_sk) AS distinct_customers,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        AVG(ws.ws_net_profit) AS avg_profit,
        CASE WHEN SUM(ws.ws_net_profit) > 0 THEN 'Profitable' ELSE 'Loss' END AS profit_flag,
        regexp_extract(w.w_warehouse_name, '(\\d+)', 1) AS warehouse_number,
        substring(d.d_quarter_name, 1, 3) AS quarter_prefix
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    WHERE regexp_like(d.d_day_name, '(Mon|Tue|Wed|Thu|Fri)')
      AND w.w_city LIKE '%' || 'York'
      AND ws.ws_net_paid > (
          SELECT avg(ws2.ws_net_paid)
          FROM web_sales ws2
      )
    GROUP BY w.w_warehouse_name, d.d_quarter_name
)
SELECT
    w_warehouse_name,
    quarter_prefix,
    distinct_orders,
    distinct_customers,
    total_sales,
    avg_profit,
    profit_flag,
    warehouse_number,
    ROW_NUMBER() OVER (PARTITION BY w_warehouse_name ORDER BY total_sales DESC) AS sales_rank
FROM agg_sales
ORDER BY total_sales DESC
LIMIT 100
