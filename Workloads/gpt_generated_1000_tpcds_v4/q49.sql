WITH sales_by_month AS (
    SELECT
        i.i_item_id,
        d.d_year,
        d.d_month_seq,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        'catalog' AS channel
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    WHERE d.d_year = 2000
      AND i.i_current_price > (SELECT AVG(i2.i_current_price) FROM item i2)
    GROUP BY i.i_item_id, d.d_year, d.d_month_seq
),
web_sales_by_month AS (
    SELECT
        i.i_item_id,
        d.d_year,
        d.d_month_seq,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        'web' AS channel
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    WHERE d.d_year = 2000
      AND i.i_current_price > (SELECT AVG(i2.i_current_price) FROM item i2)
    GROUP BY i.i_item_id, d.d_year, d.d_month_seq
)
SELECT
    combined.i_item_id,
    combined.d_year,
    combined.d_month_seq,
    combined.total_sales,
    combined.channel
FROM (
    SELECT i_item_id, d_year, d_month_seq, total_sales, channel FROM sales_by_month
    UNION ALL
    SELECT i_item_id, d_year, d_month_seq, total_sales, channel FROM web_sales_by_month
) AS combined
WHERE combined.total_sales > 1000
ORDER BY combined.d_year, combined.d_month_seq, combined.total_sales DESC
LIMIT 100
