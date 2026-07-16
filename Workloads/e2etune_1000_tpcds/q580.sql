WITH sales_agg AS (
    SELECT
        ws.ws_web_site_sk,
        ws.ws_sold_date_sk,
        t.t_hour AS sales_hour,
        SUM(ws.ws_net_profit) AS total_sales_profit,
        SUM(ws.ws_quantity) AS total_quantity_sold,
        AVG(ws.ws_coupon_amt) AS avg_coupon_amount,
        COUNT(DISTINCT ws.ws_order_number) AS distinct_orders
    FROM web_sales ws
    JOIN time_dim t ON ws.ws_sold_time_sk = t.t_time_sk
    JOIN web_site w ON ws.ws_web_site_sk = w.web_site_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    WHERE w.web_state = 'CA'
      AND i.i_category = 'Electronics'
      AND t.t_hour BETWEEN 9 AND 21
      AND ws.ws_sold_date_sk BETWEEN 2450810 AND 2450910
    GROUP BY ws.ws_web_site_sk, ws.ws_sold_date_sk, t.t_hour
),
returns_agg AS (
    SELECT
        ws.ws_web_site_sk,
        ws.ws_sold_date_sk,
        t_ret.t_hour AS return_hour,
        SUM(wr.wr_net_loss) AS total_returns_loss,
        COUNT(DISTINCT wr.wr_order_number) AS distinct_return_orders
    FROM web_returns wr
    JOIN web_sales ws ON wr.wr_order_number = ws.ws_order_number
                       AND wr.wr_item_sk = ws.ws_item_sk
    JOIN time_dim t_ret ON wr.wr_returned_time_sk = t_ret.t_time_sk
    JOIN web_site w ON ws.ws_web_site_sk = w.web_site_sk
    JOIN item i ON wr.wr_item_sk = i.i_item_sk
    WHERE w.web_state = 'CA'
      AND i.i_category = 'Electronics'
      AND t_ret.t_hour BETWEEN 9 AND 21
      AND ws.ws_sold_date_sk BETWEEN 2450810 AND 2450910
    GROUP BY ws.ws_web_site_sk, ws.ws_sold_date_sk, t_ret.t_hour
)
SELECT
    s.ws_web_site_sk,
    s.ws_sold_date_sk,
    s.sales_hour,
    s.total_sales_profit,
    s.total_quantity_sold,
    s.avg_coupon_amount,
    s.distinct_orders,
    COALESCE(r.total_returns_loss, 0) AS total_returns_loss,
    COALESCE(r.distinct_return_orders, 0) AS distinct_return_orders,
    (s.total_sales_profit - COALESCE(r.total_returns_loss, 0)) AS net_profit_after_returns
FROM sales_agg s
LEFT JOIN returns_agg r
  ON s.ws_web_site_sk = r.ws_web_site_sk
  AND s.ws_sold_date_sk = r.ws_sold_date_sk
  AND s.sales_hour = r.return_hour
WHERE s.total_sales_profit > 1000
ORDER BY net_profit_after_returns DESC
LIMIT 100
