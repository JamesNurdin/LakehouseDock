WITH selected_items AS (
    SELECT i_item_sk,
           i_category,
           i_brand
    FROM   item
    WHERE  i_category IN ('Sports', 'Books')
)
SELECT
    sales_source,
    category,
    brand,
    SUM(total_sales)   AS total_sales,
    SUM(total_quantity) AS total_quantity
FROM (
    -- Store channel sales
    SELECT
        'store' AS sales_source,
        si.i_category      AS category,
        si.i_brand         AS brand,
        ss.ss_ext_sales_price AS total_sales,
        ss.ss_quantity        AS total_quantity
    FROM   store_sales ss
    JOIN   selected_items si
           ON ss.ss_item_sk = si.i_item_sk
    JOIN   time_dim td
           ON ss.ss_sold_time_sk = td.t_time_sk
    WHERE  td.t_hour BETWEEN 9 AND 17               -- business hours
      AND  ss.ss_quantity > 0
      AND EXISTS (
          SELECT 1
          FROM   promotion p
          WHERE  p.p_item_sk = si.i_item_sk
            AND  p.p_cost > 10
      )
    UNION ALL
    -- Web channel sales
    SELECT
        'web' AS sales_source,
        wi.i_category      AS category,
        wi.i_brand         AS brand,
        ws.ws_ext_sales_price AS total_sales,
        ws.ws_quantity        AS total_quantity
    FROM   web_sales ws
    JOIN   selected_items wi
           ON ws.ws_item_sk = wi.i_item_sk
    JOIN   time_dim td2
           ON ws.ws_sold_time_sk = td2.t_time_sk
    WHERE  td2.t_hour BETWEEN 9 AND 17
      AND  ws.ws_quantity > 0
      AND EXISTS (
          SELECT 1
          FROM   promotion p
          WHERE  p.p_item_sk = wi.i_item_sk
            AND  p.p_cost > 10
      )
) AS combined
GROUP BY ROLLUP (sales_source, category, brand)
HAVING SUM(total_sales) > 0
ORDER BY sales_source, category, brand
LIMIT 100
