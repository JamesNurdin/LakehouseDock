WITH sales_agg AS (
    SELECT
        i.i_item_id,
        i.i_brand_id,
        sm.sm_ship_mode_id,
        sm.sm_code,
        SUM(cs.cs_quantity) AS total_cs_quantity,
        SUM(cs.cs_net_profit) AS total_cs_profit,
        SUM(ss.ss_quantity) AS total_ss_quantity,
        SUM(ss.ss_net_profit) AS total_ss_profit
    FROM catalog_sales cs
    JOIN ship_mode sm
        ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN item i
        ON cs.cs_item_sk = i.i_item_sk
    JOIN time_dim td
        ON cs.cs_sold_time_sk = td.t_time_sk
    JOIN store_sales ss
        ON ss.ss_item_sk = i.i_item_sk
        AND ss.ss_sold_time_sk = td.t_time_sk
    WHERE
        sm.sm_code IN ('AIR', 'SEA')
        AND sm.sm_contract <> 'qENFQ'
        AND td.t_shift = 'first'
        AND td.t_second BETWEEN 0 AND 20
        AND i.i_brand_id IN (3002001, 2002002)
        AND i.i_container = 'Unknown'
        AND cs.cs_quantity > 0
    GROUP BY i.i_item_id, i.i_brand_id, sm.sm_ship_mode_id, sm.sm_code
)
SELECT
    sm_code,
    COUNT(*) AS num_items,
    SUM(total_cs_profit + total_ss_profit) AS agg_profit,
    AVG(total_cs_profit + total_ss_profit) AS avg_item_profit
FROM sales_agg
WHERE (total_cs_profit + total_ss_profit) > (
        SELECT AVG(total_cs_profit + total_ss_profit) FROM sales_agg
    )
GROUP BY sm_code
HAVING SUM(total_cs_profit + total_ss_profit) > 10000
ORDER BY agg_profit DESC
LIMIT 100
