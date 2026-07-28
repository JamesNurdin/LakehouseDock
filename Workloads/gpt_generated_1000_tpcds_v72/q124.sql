WITH sales_summary AS (
    SELECT
        w.w_warehouse_name,
        d.d_year,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        SUM(ws.ws_net_profit) AS total_profit,
        COUNT(*) AS order_count,
        CASE WHEN SUM(ws.ws_net_profit) > 0 THEN 'Profitable' ELSE 'Loss' END AS profit_category,
        (SELECT MAX(p.p_cost) FROM promotion p) AS max_promo_cost
    FROM web_sales ws
    JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
      AND ws.ws_quantity > 0
      AND ws.ws_promo_sk IS NOT NULL
    GROUP BY w.w_warehouse_name, d.d_year
    HAVING SUM(ws.ws_ext_sales_price) > 10000
)
SELECT *
FROM sales_summary
UNION ALL
SELECT
    w.w_warehouse_name,
    d.d_year,
    SUM(wr.wr_return_amt) AS total_sales,
    SUM(wr.wr_net_loss) AS total_profit,
    COUNT(*) AS order_count,
    CASE WHEN SUM(wr.wr_net_loss) < 0 THEN 'Loss' ELSE 'Profit' END AS profit_category,
    (SELECT MAX(p.p_cost) FROM promotion p) AS max_promo_cost
FROM web_returns wr
JOIN web_sales ws ON wr.wr_order_number = ws.ws_order_number
JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
WHERE d.d_year = 2001
  AND EXISTS (
        SELECT 1 FROM reason r WHERE r.r_reason_desc LIKE '%damage%'
    )
GROUP BY w.w_warehouse_name, d.d_year
HAVING SUM(wr.wr_return_amt) > 5000
ORDER BY total_sales DESC
LIMIT 100
