WITH union_data AS (
    SELECT
        ws.ws_web_site_sk AS web_site_sk,
        ws.ws_order_number AS order_number,
        ws.ws_ext_sales_price AS total_sales,
        ws.ws_net_profit AS net_profit,
        ws.ws_sales_price AS sales_price,
        ws.ws_quantity AS quantity,
        ws.ws_ext_discount_amt AS discount_amt,
        ws.ws_ext_tax AS tax_amt,
        web_site.web_site_id,
        web_site.web_name,
        web_site.web_mkt_class,
        (SELECT AVG(ws2.ws_sales_price)
         FROM web_sales ws2
         WHERE ws2.ws_web_site_sk = ws.ws_web_site_sk) AS avg_site_price,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_web_site_sk ORDER BY ws.ws_ext_sales_price DESC) AS site_sale_rank
    FROM web_sales ws
    JOIN web_site ON ws.ws_web_site_sk = web_site.web_site_sk
    WHERE web_site.web_mkt_class LIKE 'New%'
      AND ws.ws_ext_sales_price > 5000
      AND NOT EXISTS (
          SELECT 1
          FROM web_sales ws_ex
          WHERE ws_ex.ws_web_site_sk = ws.ws_web_site_sk
            AND ws_ex.ws_net_profit < 0
      )
      AND ws.ws_quantity >= (
          SELECT MIN(ws_min.ws_quantity)
          FROM web_sales ws_min
          WHERE ws_min.ws_web_site_sk = ws.ws_web_site_sk
      )
    UNION
    SELECT
        ws.ws_web_site_sk AS web_site_sk,
        ws.ws_order_number AS order_number,
        ws.ws_ext_sales_price AS total_sales,
        ws.ws_net_profit AS net_profit,
        ws.ws_sales_price AS sales_price,
        ws.ws_quantity AS quantity,
        ws.ws_ext_discount_amt AS discount_amt,
        ws.ws_ext_tax AS tax_amt,
        web_site.web_site_id,
        web_site.web_name,
        web_site.web_mkt_class,
        (SELECT AVG(ws2.ws_sales_price)
         FROM web_sales ws2
         WHERE ws2.ws_web_site_sk = ws.ws_web_site_sk) AS avg_site_price,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_web_site_sk ORDER BY ws.ws_ext_sales_price DESC) AS site_sale_rank
    FROM web_sales ws
    JOIN web_site ON ws.ws_web_site_sk = web_site.web_site_sk
    WHERE web_site.web_city = 'San Francisco'
      AND ws.ws_ext_sales_price BETWEEN 1000 AND 3000
      AND NOT EXISTS (
          SELECT 1
          FROM web_sales ws_ex
          WHERE ws_ex.ws_web_site_sk = ws.ws_web_site_sk
            AND ws_ex.ws_net_profit < 0
      )
      AND ws.ws_quantity >= (
          SELECT MIN(ws_min.ws_quantity)
          FROM web_sales ws_min
          WHERE ws_min.ws_web_site_sk = ws.ws_web_site_sk
      )
)
SELECT
    web_site_id,
    web_name,
    total_sales,
    net_profit,
    avg_site_price,
    site_sale_rank,
    DENSE_RANK() OVER (ORDER BY total_sales DESC) AS overall_sales_rank
FROM union_data
ORDER BY total_sales DESC
LIMIT 100
