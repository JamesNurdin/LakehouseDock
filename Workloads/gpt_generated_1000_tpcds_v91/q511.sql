WITH active_items AS (
    SELECT DISTINCT i.i_item_sk,
           i.i_item_id,
           i.i_product_name
    FROM item i
    JOIN promotion p ON i.i_item_sk = p.p_item_sk
    WHERE p.p_discount_active = 'Y'
)

SELECT
    ai.i_item_id,
    ai.i_product_name,
    'catalog' AS channel,
    cs_agg.total_sales,
    cs_agg.order_cnt,
    ROW_NUMBER() OVER (PARTITION BY 'catalog' ORDER BY cs_agg.total_sales DESC) AS channel_rank
FROM (
    SELECT
        cs.cs_item_sk,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        COUNT(*) AS order_cnt
    FROM catalog_sales cs
    JOIN time_dim t ON cs.cs_sold_time_sk = t.t_time_sk
    WHERE t.t_hour BETWEEN 9 AND 17
    GROUP BY cs.cs_item_sk
    HAVING SUM(cs.cs_ext_sales_price) > (
        SELECT AVG(item_sales) FROM (
            SELECT SUM(cs2.cs_ext_sales_price) AS item_sales
            FROM catalog_sales cs2
            JOIN time_dim t2 ON cs2.cs_sold_time_sk = t2.t_time_sk
            WHERE t2.t_hour BETWEEN 9 AND 17
            GROUP BY cs2.cs_item_sk
        ) avg_sub
    )
) cs_agg
JOIN active_items ai ON ai.i_item_sk = cs_agg.cs_item_sk

UNION

SELECT
    ai.i_item_id,
    ai.i_product_name,
    'store' AS channel,
    ss_agg.total_sales,
    ss_agg.order_cnt,
    ROW_NUMBER() OVER (PARTITION BY 'store' ORDER BY ss_agg.total_sales DESC) AS channel_rank
FROM (
    SELECT
        ss.ss_item_sk,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        COUNT(*) AS order_cnt
    FROM store_sales ss
    JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
    WHERE t.t_hour BETWEEN 9 AND 17
    GROUP BY ss.ss_item_sk
    HAVING SUM(ss.ss_ext_sales_price) > (
        SELECT AVG(item_sales) FROM (
            SELECT SUM(ss2.ss_ext_sales_price) AS item_sales
            FROM store_sales ss2
            JOIN time_dim t2 ON ss2.ss_sold_time_sk = t2.t_time_sk
            WHERE t2.t_hour BETWEEN 9 AND 17
            GROUP BY ss2.ss_item_sk
        ) avg_sub2
    )
) ss_agg
JOIN active_items ai ON ai.i_item_sk = ss_agg.ss_item_sk
ORDER BY channel, channel_rank
LIMIT 100
