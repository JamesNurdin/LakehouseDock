WITH catalog_agg AS (
    SELECT
        i.i_category AS category,
        i.i_item_id AS item_id,
        SUM(cs.cs_net_paid) AS total_sales,
        'catalog' AS source
    FROM tpcds.catalog_sales cs
    JOIN tpcds.item i ON cs.cs_item_sk = i.i_item_sk
    JOIN tpcds.time_dim td ON cs.cs_sold_time_sk = td.t_time_sk
    JOIN tpcds.ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN tpcds.call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    WHERE sm.sm_code = 'AIR'
      AND td.t_am_pm = 'PM'
    GROUP BY i.i_category, i.i_item_id
),
store_agg AS (
    SELECT
        i.i_category AS category,
        i.i_item_id AS item_id,
        SUM(ss.ss_net_paid) AS total_sales,
        'store' AS source
    FROM tpcds.store_sales ss
    JOIN tpcds.item i ON ss.ss_item_sk = i.i_item_sk
    JOIN tpcds.time_dim td ON ss.ss_sold_time_sk = td.t_time_sk
    JOIN tpcds.store s ON ss.ss_store_sk = s.s_store_sk
    WHERE s.s_state = 'CA'
      AND td.t_am_pm = 'AM'
    GROUP BY i.i_category, i.i_item_id
)
SELECT
    category,
    item_id,
    total_sales,
    source,
    RANK() OVER (PARTITION BY source ORDER BY total_sales DESC) AS sales_rank
FROM (
    SELECT * FROM catalog_agg
    UNION ALL
    SELECT * FROM store_agg
) combined
ORDER BY source, sales_rank
LIMIT 100
