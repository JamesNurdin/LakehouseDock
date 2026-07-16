WITH combined_sales AS (
    SELECT cs.cs_sold_date_sk AS date_sk, cs.cs_item_sk AS item_sk, cs.cs_ext_sales_price AS sales_amount, 'catalog' AS channel
    FROM catalog_sales cs
    UNION ALL
    SELECT ss.ss_sold_date_sk, ss.ss_item_sk, ss.ss_ext_sales_price, 'store'
    FROM store_sales ss
    UNION ALL
    SELECT ws.ws_sold_date_sk, ws.ws_item_sk, ws.ws_ext_sales_price, 'web'
    FROM web_sales ws
), aggregated AS (
    SELECT d.d_year,
           i.i_category,
           s.channel,
           SUM(s.sales_amount) AS total_sales
    FROM combined_sales s
    JOIN date_dim d ON s.date_sk = d.d_date_sk
    JOIN item i ON s.item_sk = i.i_item_sk
    WHERE d.d_year BETWEEN 1999 AND 2001
    GROUP BY d.d_year, i.i_category, s.channel
)
SELECT agg.d_year,
       agg.i_category,
       agg.channel,
       agg.total_sales
FROM (
    SELECT a.*,
           ROW_NUMBER() OVER (PARTITION BY a.d_year, a.channel ORDER BY a.total_sales DESC) AS rn
    FROM aggregated a
) agg
WHERE agg.rn <= 5
ORDER BY agg.d_year, agg.channel, agg.total_sales DESC
