WITH avg_qty AS (
    SELECT avg(ws_quantity) AS avg_qty FROM web_sales
)
SELECT
    web_name,
    fiscal_year,
    net_profit,
    max_price
FROM (
    SELECT
        wsite.web_name,
        ws_sold.d_fy_year AS fiscal_year,
        ws.ws_net_profit AS net_profit,
        lt.max_price
    FROM web_sales ws
    JOIN date_dim ws_sold ON ws.ws_sold_date_sk = ws_sold.d_date_sk
    JOIN web_site wsite ON ws.ws_web_site_sk = wsite.web_site_sk
    CROSS JOIN LATERAL (
        SELECT max(ws2.ws_sales_price) AS max_price
        FROM web_sales ws2
        WHERE ws2.ws_web_site_sk = ws.ws_web_site_sk
          AND ws2.ws_sold_date_sk = ws.ws_sold_date_sk
    ) lt
    WHERE ws_sold.d_fy_year = 1910
      AND ws.ws_quantity > (SELECT avg_qty FROM avg_qty)
      AND ws.ws_quantity > 30

    UNION ALL

    SELECT
        wsite.web_name,
        ws_sold.d_fy_year AS fiscal_year,
        ws.ws_net_profit AS net_profit,
        lt.max_price
    FROM web_sales ws
    JOIN date_dim ws_sold ON ws.ws_sold_date_sk = ws_sold.d_date_sk
    JOIN web_site wsite ON ws.ws_web_site_sk = wsite.web_site_sk
    CROSS JOIN LATERAL (
        SELECT max(ws2.ws_sales_price) AS max_price
        FROM web_sales ws2
        WHERE ws2.ws_web_site_sk = ws.ws_web_site_sk
          AND ws2.ws_sold_date_sk = ws.ws_sold_date_sk
    ) lt
    WHERE ws_sold.d_fy_year = 1911
      AND ws.ws_quantity <= (SELECT avg_qty FROM avg_qty)
      AND ws.ws_quantity <= 30
) combined
ORDER BY web_name, fiscal_year
LIMIT 100
