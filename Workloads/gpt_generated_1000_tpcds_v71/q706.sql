WITH unified_sales AS (
    SELECT
        i.i_brand,
        td.t_hour,
        ss.ss_net_paid AS sales,
        'store' AS channel
    FROM store_sales ss
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN time_dim td ON ss.ss_sold_time_sk = td.t_time_sk
    WHERE ss.ss_quantity > 0
      AND td.t_hour BETWEEN 9 AND 17
    UNION ALL
    SELECT
        i.i_brand,
        td.t_hour,
        cs.cs_net_paid AS sales,
        'catalog' AS channel
    FROM catalog_sales cs
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN time_dim td ON cs.cs_sold_time_sk = td.t_time_sk
    WHERE cs.cs_quantity > 0
      AND td.t_hour BETWEEN 9 AND 17
)
SELECT
    i_brand,
    t_hour,
    channel,
    SUM(sales) AS total_sales
FROM unified_sales
GROUP BY GROUPING SETS (
    (i_brand, t_hour, channel),
    (i_brand, channel),
    (t_hour, channel),
    (channel),
    ()
)
ORDER BY i_brand, t_hour, channel
LIMIT 100
