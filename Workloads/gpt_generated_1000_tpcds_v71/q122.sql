WITH combined AS (
    SELECT
        s.web_site_sk,
        s.web_site_id,
        d.d_year,
        CASE WHEN ws.ws_net_profit > 0 THEN 'Profitable' ELSE 'Loss' END AS profit_status,
        SUM(ws.ws_net_profit) AS total_net_profit,
        SUM(COALESCE(wr.wr_return_amt_inc_tax, 0)) AS total_return_inc_tax,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS distinct_orders
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN web_site s ON ws.ws_web_site_sk = s.web_site_sk
    LEFT JOIN web_returns wr
        ON ws.ws_item_sk = wr.wr_item_sk
        AND ws.ws_order_number = wr.wr_order_number
        AND wr.wr_returned_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
      AND s.web_country = 'United States'
      AND ws.ws_quantity > 0
      AND ws.ws_net_paid > 1000
      AND (wr.wr_return_amt_inc_tax IS NULL OR wr.wr_return_amt_inc_tax > 0)
    GROUP BY s.web_site_sk, s.web_site_id, d.d_year,
        CASE WHEN ws.ws_net_profit > 0 THEN 'Profitable' ELSE 'Loss' END
)
SELECT
    c.web_site_id,
    c.d_year,
    c.profit_status,
    c.total_net_profit,
    c.total_return_inc_tax,
    c.total_sales,
    c.distinct_orders,
    CASE WHEN c.total_net_profit > (SELECT AVG(total_net_profit) FROM combined) THEN 'Above Avg' ELSE 'Below Avg' END AS profit_vs_avg
FROM combined c
WHERE c.total_return_inc_tax > 500
  AND c.total_net_profit > 0
  AND c.distinct_orders >= 10
ORDER BY c.total_net_profit DESC
LIMIT 100
