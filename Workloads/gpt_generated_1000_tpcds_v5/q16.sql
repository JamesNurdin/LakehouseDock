WITH sales_agg AS (
    SELECT
        i.i_item_sk,
        i.i_product_name,
        i.i_color,
        ws.ws_web_site_sk AS web_site_sk,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        SUM(ws.ws_quantity) AS total_qty,
        AVG(ws.ws_net_paid_inc_tax) AS avg_paid_inc_tax
    FROM web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN web_site w ON ws.ws_web_site_sk = w.web_site_sk
    WHERE i.i_color IN ('papaya', 'olive')
      AND w.web_country = 'United States'
      AND ws.ws_net_paid_inc_tax > 500
      AND EXISTS (
          SELECT 1
          FROM item i2
          WHERE i2.i_brand_id = i.i_brand_id
            AND i2.i_color <> i.i_color
      )
    GROUP BY
        i.i_item_sk,
        i.i_product_name,
        i.i_color,
        ws.ws_web_site_sk
)
SELECT
    w.web_name,
    s.i_product_name,
    s.i_color,
    s.total_sales,
    s.total_qty,
    RANK() OVER (PARTITION BY s.web_site_sk ORDER BY s.total_sales DESC) AS sales_rank,
    SUM(s.total_sales) OVER (
        PARTITION BY s.web_site_sk
        ORDER BY s.total_sales DESC
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS cumulative_sales
FROM sales_agg s
JOIN web_site w ON s.web_site_sk = w.web_site_sk
ORDER BY w.web_name, sales_rank
LIMIT 100
