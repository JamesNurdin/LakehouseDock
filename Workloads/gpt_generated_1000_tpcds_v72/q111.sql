WITH store_item_returns AS (
    SELECT
        s.s_store_id,
        i.i_brand,
        i.i_color,
        i.i_formulation,
        s.s_zip,
        s.s_geography_class,
        SUM(sr.sr_net_loss) AS total_net_loss,
        SUM(sr.sr_return_quantity) AS total_return_qty,
        AVG(sr.sr_fee) AS avg_fee,
        CASE WHEN i.i_color = 'sandy' THEN 'Sandy' ELSE 'Other' END AS color_group
    FROM tpcds.store_returns sr
    JOIN tpcds.item i
        ON sr.sr_item_sk = i.i_item_sk
    JOIN tpcds.store s
        ON sr.sr_store_sk = s.s_store_sk
    WHERE i.i_color IN ('sandy', 'pink')
      AND i.i_formulation LIKE '%goldenrod%'
      AND s.s_zip LIKE '3%'
      AND s.s_geography_class = 'Unknown'
      AND sr.sr_return_ship_cost > 50
      AND sr.sr_fee < 100
      AND sr.sr_return_quantity >= 1
    GROUP BY s.s_store_id,
        i.i_brand,
        i.i_color,
        i.i_formulation,
        s.s_zip,
        s.s_geography_class,
        CASE WHEN i.i_color = 'sandy' THEN 'Sandy' ELSE 'Other' END
)
SELECT
    color_group,
    COUNT(DISTINCT s_store_id) AS store_count,
    AVG(total_net_loss) AS avg_total_net_loss,
    SUM(total_return_qty) AS sum_return_qty,
    AVG(avg_fee) AS avg_fee_across_groups
FROM store_item_returns
GROUP BY color_group
HAVING AVG(total_net_loss) > 1000
ORDER BY avg_total_net_loss DESC
