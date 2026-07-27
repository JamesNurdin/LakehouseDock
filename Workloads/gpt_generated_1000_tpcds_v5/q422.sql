SELECT
    sales_source,
    d_year,
    category,
    total_net_profit
FROM (
        SELECT
            'catalog' AS sales_source,
            d.d_year,
            cp.cp_department AS category,
            SUM(cs.cs_net_profit) AS total_net_profit
        FROM catalog_sales cs
        JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
        JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
        JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
        WHERE cp.cp_department = 'Books'
          AND d.d_year = 1903
          AND w.w_state = 'CA'
          AND d.d_quarter_seq = (
                SELECT MAX(d2.d_quarter_seq)
                FROM date_dim d2
                WHERE d2.d_year = 1903
          )
        GROUP BY d.d_year, cp.cp_department
    )
UNION ALL
SELECT
    'web' AS sales_source,
    d.d_year,
    wp.wp_type AS category,
    SUM(ws.ws_net_profit) AS total_net_profit
FROM web_sales ws
JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
WHERE wp.wp_type = 'product'
  AND d.d_year = 1903
  AND w.w_state = 'CA'
  AND d.d_quarter_seq = (
        SELECT MAX(d2.d_quarter_seq)
        FROM date_dim d2
        WHERE d2.d_year = 1903
  )
GROUP BY d.d_year, wp.wp_type
ORDER BY total_net_profit DESC
LIMIT 100
