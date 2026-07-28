/* Goal: Identify top-selling ship modes and promotion channels for a specific time slice, summarizing revenue and profit while comparing to overall profit benchmarks. */
WITH filtered_sales AS (
    SELECT
        cs.cs_ext_sales_price,
        cs.cs_quantity,
        cs.cs_net_profit,
        sm.sm_type,
        sm.sm_code,
        sm.sm_contract,
        p.p_channel_dmail,
        p.p_channel_radio,
        p.p_response_target,
        t.t_time_id,
        t.t_minute,
        t.t_second
    FROM catalog_sales cs
    JOIN ship_mode sm
        ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN promotion p
        ON cs.cs_promo_sk = p.p_promo_sk
    JOIN time_dim t
        ON cs.cs_sold_time_sk = t.t_time_sk
    WHERE t.t_time_id = 'AAAAAAAAGAAAAAAA'
      AND t.t_minute BETWEEN 10 AND 30
      AND p.p_channel_radio = 'N'
      AND sm.sm_contract = 'GNJr3g5i7oorKqtX'
),
agg_sales AS (
    SELECT
        sm_type,
        p_channel_dmail,
        SUM(cs_ext_sales_price) AS total_sales,
        AVG(cs_net_profit) AS avg_profit,
        COUNT(*) AS txn_count,
        SUM(CASE WHEN cs_quantity > 5 THEN cs_ext_sales_price ELSE 0 END) AS sales_qty_gt5
    FROM filtered_sales
    GROUP BY GROUPING SETS (
        (sm_type, p_channel_dmail),
        (sm_type),
        (p_channel_dmail),
        ()
    )
)
SELECT
    ag.sm_type,
    ag.p_channel_dmail,
    ag.total_sales,
    ag.avg_profit,
    ag.txn_count,
    ag.sales_qty_gt5,
    (SELECT AVG(cs_net_profit) FROM filtered_sales) AS overall_avg_profit,
    ROW_NUMBER() OVER (PARTITION BY ag.sm_type ORDER BY ag.total_sales DESC) AS rank_within_type
FROM agg_sales ag
ORDER BY ag.total_sales DESC
LIMIT 100
