WITH base AS (
    SELECT
        w.w_warehouse_name,
        r.r_reason_desc,
        ws.ws_order_number,
        ws.ws_ext_sales_price,
        ws.ws_net_profit,
        wr.wr_return_amt,
        ws.ws_quantity,
        ws.ws_sold_date_sk
    FROM web_sales ws
    JOIN warehouse w
        ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN web_returns wr
        ON ws.ws_order_number = wr.wr_order_number
        AND ws.ws_item_sk = wr.wr_item_sk
    JOIN reason r
        ON wr.wr_reason_sk = r.r_reason_sk
    WHERE w.w_city = 'San Francisco'
      AND w.w_state = 'CA'
      AND w.w_zip = '64593'
      AND ws.ws_quantity > 2
      AND ws.ws_ext_sales_price >= 100.00
      AND r.r_reason_desc LIKE '%damaged%'
      AND ws.ws_sold_date_sk BETWEEN 2450000 AND 2452000
      AND ws.ws_ext_sales_price > (
          SELECT max(ws2.ws_ext_sales_price)
          FROM web_sales ws2
      )
),
agg AS (
    SELECT
        b.w_warehouse_name,
        b.r_reason_desc,
        SUM(b.wr_return_amt) AS total_return_amount,
        SUM(b.ws_ext_sales_price) AS total_sales_amount,
        SUM(b.ws_net_profit) AS total_net_profit,
        COUNT(DISTINCT b.ws_order_number) AS distinct_orders,
        SUM(b.wr_return_amt) / NULLIF(SUM(b.ws_ext_sales_price), 0) AS return_to_sales_ratio
    FROM base b
    GROUP BY b.w_warehouse_name, b.r_reason_desc
    HAVING SUM(b.wr_return_amt) > 5000
       AND AVG(b.ws_ext_sales_price) > 200
)
SELECT
    a.w_warehouse_name,
    AVG(a.total_return_amount) AS avg_return_amount,
    SUM(a.total_sales_amount) AS sum_sales_amount,
    COUNT(*) AS warehouse_reason_count
FROM agg a
WHERE a.return_to_sales_ratio < 0.10
GROUP BY a.w_warehouse_name
ORDER BY avg_return_amount DESC
LIMIT 100
