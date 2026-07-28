SELECT
    d.d_year,
    regexp_extract(wp.wp_url, '/category/([^/]+)/', 1) AS category,
    SUM(ws.ws_net_paid) AS total_net_paid,
    COUNT(*) AS sales_count
FROM
    web_sales ws
JOIN
    date_dim d
      ON ws.ws_sold_date_sk = d.d_date_sk
JOIN
    web_page wp
      ON ws.ws_web_page_sk = wp.wp_web_page_sk
JOIN
    warehouse w
      ON ws.ws_warehouse_sk = w.w_warehouse_sk
WHERE
    d.d_year = 2000
    AND regexp_like(wp.wp_url, '^https?://[^/]+/promo/.*')
    AND wp.wp_web_page_id LIKE 'AAAAAAA%'
    AND EXISTS (
        SELECT 1
        FROM inventory inv
        WHERE inv.inv_date_sk = ws.ws_sold_date_sk
          AND inv.inv_warehouse_sk = ws.ws_warehouse_sk
          AND inv.inv_quantity_on_hand > 0
    )
GROUP BY
    d.d_year,
    regexp_extract(wp.wp_url, '/category/([^/]+)/', 1)
ORDER BY
    total_net_paid DESC
LIMIT 100
