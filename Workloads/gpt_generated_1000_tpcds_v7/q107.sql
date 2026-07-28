WITH store_agg AS (
    SELECT
        'store' AS source_type,
        s.s_store_id AS entity_id,
        d.d_year AS year,
        SUM(ss.ss_net_profit) AS total_net_profit
    FROM store_sales ss
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE d.d_year BETWEEN 2000 AND 2002
    GROUP BY s.s_store_id, d.d_year
),
call_center_agg AS (
    SELECT
        'call_center' AS source_type,
        cc.cc_call_center_id AS entity_id,
        d.d_year AS year,
        SUM(cs.cs_net_profit) AS total_net_profit
    FROM catalog_sales cs
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    WHERE d.d_year BETWEEN 2000 AND 2002
    GROUP BY cc.cc_call_center_id, d.d_year
),
combined AS (
    SELECT * FROM store_agg
    UNION ALL
    SELECT * FROM call_center_agg
)
SELECT
    source_type,
    entity_id,
    year,
    total_net_profit,
    ROW_NUMBER() OVER (PARTITION BY source_type, year ORDER BY total_net_profit DESC) AS profit_rank
FROM combined
ORDER BY source_type, year, profit_rank
LIMIT 100
