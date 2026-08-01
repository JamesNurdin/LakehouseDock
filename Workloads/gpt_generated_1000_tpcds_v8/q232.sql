WITH
  sales_sold AS (
    SELECT
      ws.ws_web_site_sk,
      d.d_date AS sale_date,
      SUM(ws.ws_ext_sales_price) AS total_sales,
      SUM(ws.ws_net_profit) AS total_profit
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN web_site w ON ws.ws_web_site_sk = w.web_site_sk
    WHERE d.d_holiday = 'N'
      AND w.web_mkt_desc LIKE '%Electric%'
    GROUP BY ws.ws_web_site_sk, d.d_date
  ),
  sales_ship AS (
    SELECT
      ws.ws_web_site_sk,
      d.d_date AS ship_date,
      SUM(ws.ws_ext_sales_price) AS total_sales,
      SUM(ws.ws_net_profit) AS total_profit
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_ship_date_sk = d.d_date_sk
    JOIN web_site w ON ws.ws_web_site_sk = w.web_site_sk
    WHERE d.d_holiday = 'N'
      AND w.web_mkt_desc LIKE '%Electric%'
    GROUP BY ws.ws_web_site_sk, d.d_date
  ),
  avg_daily_sales AS (
    SELECT AVG(daily_sales) AS avg_sales FROM (
      SELECT SUM(ws.ws_ext_sales_price) AS daily_sales
      FROM web_sales ws
      JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
      WHERE d.d_holiday = 'N'
      GROUP BY d.d_date
    ) t
  ),
  high_sold_sites AS (
    SELECT DISTINCT ws_web_site_sk
    FROM sales_sold
    WHERE total_sales > (SELECT avg_sales FROM avg_daily_sales)
  ),
  high_ship_sites AS (
    SELECT DISTINCT ws_web_site_sk
    FROM sales_ship
    WHERE total_sales > (SELECT avg_sales FROM avg_daily_sales)
  ),
  only_sold_exclusive AS (
    SELECT hs.ws_web_site_sk
    FROM high_sold_sites hs
    EXCEPT
    SELECT hs.ws_web_site_sk
    FROM high_ship_sites hs
  ),
  profit_above AS (
    SELECT ws_web_site_sk
    FROM sales_sold
    GROUP BY ws_web_site_sk
    HAVING SUM(total_profit) > 10000
  ),
  final_sites AS (
    SELECT ws_web_site_sk FROM only_sold_exclusive
    INTERSECT
    SELECT ws_web_site_sk FROM profit_above
  )
SELECT
  w.web_name,
  f.ws_web_site_sk,
  SUM(s.total_sales) AS site_total_sales,
  CASE WHEN SUM(s.total_sales) > 50000 THEN 'High' ELSE 'Medium' END AS sales_category,
  ROW_NUMBER() OVER (PARTITION BY w.web_name ORDER BY SUM(s.total_sales) DESC) AS sales_rank
FROM final_sites f
JOIN web_site w ON f.ws_web_site_sk = w.web_site_sk
JOIN sales_sold s ON s.ws_web_site_sk = f.ws_web_site_sk
WHERE w.web_country = 'United States'
GROUP BY w.web_name, f.ws_web_site_sk
HAVING COUNT(DISTINCT s.sale_date) >= 5
ORDER BY site_total_sales DESC
LIMIT 100
