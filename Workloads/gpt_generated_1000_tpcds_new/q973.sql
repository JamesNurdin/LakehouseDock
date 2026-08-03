WITH sampled_catalog_sales AS (
    SELECT
        cs_call_center_sk,
        cs_item_sk,
        cs_net_profit,
        cs_sold_date_sk
    FROM catalog_sales
    TABLESAMPLE BERNOULLI (10)
)
SELECT
    COALESCE(cc.cc_state, 'UNKNOWN') AS state,
    COUNT(DISTINCT cs.cs_item_sk) AS distinct_items_sold,
    COUNT(DISTINCT cc.cc_call_center_id) AS distinct_call_center_ids,
    SUM(CASE WHEN cs.cs_net_profit > 0 THEN cs.cs_net_profit ELSE 0 END) AS total_positive_profit,
    SUM(CASE WHEN cs.cs_net_profit < 0 THEN cs.cs_net_profit ELSE 0 END) AS total_negative_profit,
    COUNT(*) AS total_rows,
    REGEXP_EXTRACT(cc.cc_name, '(\\d+)', 1) AS extracted_number_from_name,
    CASE
        WHEN REGEXP_LIKE(cc.cc_name, 'Center') THEN 'HasCenter'
        ELSE 'NoCenter'
    END AS name_category
FROM call_center AS cc
FULL OUTER JOIN sampled_catalog_sales AS cs
    ON cc.cc_call_center_sk = cs.cs_call_center_sk
LEFT JOIN date_dim AS d
    ON cs.cs_sold_date_sk = d.d_date_sk
WHERE (
        d.d_year = 2001
        OR d.d_year IS NULL
    )
  AND (cc.cc_name LIKE '%Call%' OR cc.cc_name IS NULL)
GROUP BY
    COALESCE(cc.cc_state, 'UNKNOWN'),
    REGEXP_EXTRACT(cc.cc_name, '(\\d+)', 1),
    CASE
        WHEN REGEXP_LIKE(cc.cc_name, 'Center') THEN 'HasCenter'
        ELSE 'NoCenter'
    END
ORDER BY total_positive_profit DESC
LIMIT 100
