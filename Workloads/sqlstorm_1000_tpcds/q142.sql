WITH date_filter AS (
    SELECT d_date_sk
    FROM date_dim
    WHERE d_year = (SELECT MAX(d_year) FROM date_dim) - 1
),
sales_aggregation AS (
    SELECT cs.cs_call_center_sk,
           SUM(cs.cs_net_profit) AS store_sales_profit,
           SUM(cs.cs_ext_sales_price) AS store_sales_rev,
           COUNT(*) AS store_sales_cnt
    FROM catalog_sales cs
    JOIN date_filter df ON cs.cs_sold_date_sk = df.d_date_sk
    GROUP BY cs.cs_call_center_sk
),
returns_aggregation AS (
    SELECT cr.cr_call_center_sk,
           SUM(cr.cr_net_loss) AS return_loss,
           SUM(cr.cr_return_quantity) AS return_qty
    FROM catalog_returns cr
    LEFT JOIN date_filter df ON cr.cr_returned_date_sk = df.d_date_sk
    GROUP BY cr.cr_call_center_sk
),
call_center_enriched AS (
    SELECT cc.cc_call_center_sk,
           COALESCE(sa.store_sales_profit, 0) - COALESCE(ra.return_loss, 0) AS net_profit_adj,
           COALESCE(sa.store_sales_rev, 0) AS total_rev,
           COALESCE(sa.store_sales_cnt, 0) AS total_sales_cnt,
           cc.cc_mkt_id,
           cc.cc_state,
           COALESCE(cc.cc_gmt_offset, 0) AS gmt_offset,
           CONCAT(cc.cc_name, ' - ', COALESCE(cc.cc_class, 'UNKNOWN')) AS cc_display_name,
           (SELECT COUNT(DISTINCT cs_item_sk)
            FROM catalog_sales cs_sub
            WHERE cs_sub.cs_call_center_sk = cc.cc_call_center_sk) AS distinct_items_sold,
           ROW_NUMBER() OVER (ORDER BY (COALESCE(sa.store_sales_profit, 0) - COALESCE(ra.return_loss, 0)) DESC) AS overall_rank
    FROM call_center cc
    LEFT JOIN sales_aggregation sa ON cc.cc_call_center_sk = sa.cs_call_center_sk
    LEFT JOIN returns_aggregation ra ON cc.cc_call_center_sk = ra.cr_call_center_sk
),
market_aggregates AS (
    SELECT ca.cc_call_center_sk,
           COALESCE(ca.cc_mkt_id, -1) AS market_id,
           ca.cc_state,
           SUM(ca.net_profit_adj) AS profit_by_market
    FROM call_center_enriched ca
    GROUP BY GROUPING SETS (
        (ca.cc_call_center_sk, ca.cc_mkt_id, ca.cc_state),
        (ca.cc_call_center_sk, ca.cc_mkt_id),
        (ca.cc_call_center_sk, ca.cc_state),
        (ca.cc_call_center_sk)
    )
),
complex_set AS (
    SELECT ce.overall_rank,
           ce.cc_display_name,
           ce.net_profit_adj,
           ce.total_rev,
           ce.distinct_items_sold,
           ma.profit_by_market,
           ma.market_id,
           ma.cc_state
    FROM call_center_enriched ce
    JOIN market_aggregates ma ON ce.cc_call_center_sk = ma.cc_call_center_sk
    WHERE ce.net_profit_adj > 0

    UNION ALL

    SELECT 0 AS overall_rank,
           'TOTAL_AGG' AS cc_display_name,
           SUM(net_profit_adj) OVER () AS net_profit_adj,
           SUM(total_rev) OVER () AS total_rev,
           NULL AS distinct_items_sold,
           NULL AS profit_by_market,
           NULL AS market_id,
           NULL AS cc_state
    FROM call_center_enriched
    WHERE net_profit_adj > 0
),
final_window AS (
    SELECT overall_rank,
           REGEXP_REPLACE(cc_display_name, '[^A-Za-z0-9 ]', '') AS sanitized_name,
           net_profit_adj,
           total_rev,
           distinct_items_sold,
           profit_by_market,
           market_id,
           cc_state,
           CASE
               WHEN net_profit_adj < 0 THEN 'LOSS'
               WHEN net_profit_adj = 0 THEN 'BREAKEVEN'
               ELSE 'PROFIT'
           END AS profit_category,
           COALESCE(NULLIF(REGEXP_REPLACE(cc_display_name, '[^A-Za-z0-9 ]', ''), ''), 'MISSING') AS cleaned_name,
           PERCENT_RANK() OVER (ORDER BY net_profit_adj DESC) AS profit_percent_rank,
           SUM(net_profit_adj) OVER (ORDER BY overall_rank ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_profit,
           ROW_NUMBER() OVER (PARTITION BY market_id ORDER BY net_profit_adj DESC) AS market_rank
    FROM complex_set
)
SELECT *
FROM final_window
WHERE overall_rank <= 10
ORDER BY overall_rank
