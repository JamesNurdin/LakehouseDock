WITH store_sales_agg AS (
    SELECT
        i.i_item_id AS item_id,
        s.s_store_id AS store_id,
        SUM(ss.ss_net_profit) AS total_profit,
        CASE WHEN SUM(ss.ss_net_profit) > 0 THEN 'POSITIVE' ELSE 'NON_POSITIVE' END AS profit_flag,
        'store' AS sales_channel
    FROM store_sales ss
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
    WHERE s.s_state = 'CA'
      AND ss.ss_sold_date_sk BETWEEN 2451910 AND 2451920
    GROUP BY i.i_item_id, s.s_store_id
),
catalog_sales_agg AS (
    SELECT
        i.i_item_id AS item_id,
        cp.cp_catalog_page_id AS store_id,
        SUM(cs.cs_net_profit) AS total_profit,
        CASE WHEN SUM(cs.cs_net_profit) > 0 THEN 'POSITIVE' ELSE 'NON_POSITIVE' END AS profit_flag,
        'catalog' AS sales_channel
    FROM catalog_sales cs
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN time_dim t ON cs.cs_sold_time_sk = t.t_time_sk
    WHERE cp.cp_type = 'Promotion'
      AND cs.cs_sold_date_sk BETWEEN 2451910 AND 2451920
    GROUP BY i.i_item_id, cp.cp_catalog_page_id
)
SELECT *
FROM store_sales_agg
UNION ALL
SELECT *
FROM catalog_sales_agg
ORDER BY total_profit DESC
LIMIT 100
