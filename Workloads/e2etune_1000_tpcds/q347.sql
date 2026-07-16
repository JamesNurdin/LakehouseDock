WITH sales_agg AS (
  SELECT
    ws.ws_web_site_sk,
    ws_site.web_name,
    wp.wp_type,
    SUM(ws.ws_ext_sales_price) AS total_sales,
    SUM(ws.ws_ext_discount_amt) AS total_discount,
    SUM(ws.ws_net_profit) AS total_net_profit,
    SUM(ws.ws_quantity) AS total_quantity
  FROM web_sales ws
  JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
  JOIN web_site ws_site ON ws.ws_web_site_sk = ws_site.web_site_sk
  WHERE wp.wp_type IN ('ad', 'general')
    AND wp.wp_access_date_sk BETWEEN 2452570 AND 2452620
    AND ws.ws_sold_date_sk >= 2450800
  GROUP BY ws.ws_web_site_sk, ws_site.web_name, wp.wp_type
),
returns_agg AS (
  SELECT
    ws.ws_web_site_sk,
    wp.wp_type,
    SUM(wr.wr_return_quantity) AS total_return_qty,
    SUM(wr.wr_return_amt) AS total_return_amount
  FROM web_returns wr
  JOIN web_sales ws ON wr.wr_order_number = ws.ws_order_number
                     AND wr.wr_item_sk = ws.ws_item_sk
  JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
  GROUP BY ws.ws_web_site_sk, wp.wp_type
)
SELECT
  s.ws_web_site_sk,
  s.web_name,
  s.wp_type,
  s.total_sales,
  s.total_discount,
  s.total_net_profit,
  COALESCE(r.total_return_qty, 0) AS total_return_qty,
  COALESCE(r.total_return_amount, 0) AS total_return_amount,
  CASE WHEN s.total_quantity = 0 THEN 0
       ELSE (COALESCE(r.total_return_qty, 0) * 100.0) / s.total_quantity END AS return_qty_pct,
  RANK() OVER (ORDER BY s.total_net_profit DESC) AS net_profit_rank
FROM sales_agg s
LEFT JOIN returns_agg r
  ON s.ws_web_site_sk = r.ws_web_site_sk
  AND s.wp_type = r.wp_type
WHERE s.total_sales > 10000
ORDER BY s.total_net_profit DESC
LIMIT 100
