WITH sales_agg AS (
    SELECT
        ws.ws_item_sk,
        ws.ws_web_site_sk,
        SUM(ws.ws_net_paid) AS total_net_paid,
        COUNT(*) AS sales_cnt,
        MIN(ws.ws_sold_date_sk) AS first_sold_date_sk
    FROM web_sales ws
    JOIN web_site wsite
        ON ws.ws_web_site_sk = wsite.web_site_sk
    WHERE wsite.web_name LIKE '%Online%'
    GROUP BY ws.ws_item_sk, ws.ws_web_site_sk
)
SELECT
    w.web_name,
    i.i_item_id,
    i.i_product_name,
    CONCAT(i.i_brand, ' ', i.i_product_name) AS brand_product,
    SUBSTRING(i.i_item_desc FROM 1 FOR 15) AS short_desc,
    REGEXP_EXTRACT(i.i_item_desc, '(\\d{3})', 1) AS extracted_code,
    s.total_net_paid,
    s.sales_cnt,
    ROW_NUMBER() OVER (PARTITION BY w.web_name ORDER BY s.total_net_paid DESC) AS rn
FROM sales_agg s
JOIN item i
    ON s.ws_item_sk = i.i_item_sk
JOIN web_site w
    ON s.ws_web_site_sk = w.web_site_sk
WHERE REGEXP_LIKE(i.i_item_desc, '[A-Z]{2}[0-9]{3}')
  AND EXISTS (
        SELECT 1
        FROM web_returns wr
        JOIN web_sales ws2
            ON wr.wr_order_number = ws2.ws_order_number
        WHERE ws2.ws_item_sk = s.ws_item_sk
          AND ws2.ws_web_site_sk = s.ws_web_site_sk
    )
ORDER BY s.total_net_paid DESC
LIMIT 100
