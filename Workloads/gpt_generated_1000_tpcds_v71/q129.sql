WITH catalog_agg AS (
    SELECT
        'Catalog' AS source_type,
        cc.cc_name AS entity_name,
        CASE WHEN cc.cc_gmt_offset > 0 THEN 'East' ELSE 'West' END AS region,
        SUM(cs.cs_net_profit) AS total_profit,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        AVG(cs.cs_net_profit) AS avg_profit_per_sale,
        ROW_NUMBER() OVER (
            PARTITION BY CASE WHEN cc.cc_gmt_offset > 0 THEN 'East' ELSE 'West' END
            ORDER BY SUM(cs.cs_net_profit) DESC
        ) AS rank_in_region
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    WHERE d.d_year = 1998
      AND regexp_like(cc.cc_manager, '^.*\\sB.*$')   -- manager name contains a space and a B
      AND cc.cc_city LIKE '%ville%'
    GROUP BY cc.cc_name, cc.cc_gmt_offset
    HAVING SUM(cs.cs_net_profit) > (
        SELECT AVG(cs2.cs_net_profit)
        FROM catalog_sales cs2
        JOIN date_dim d2 ON cs2.cs_sold_date_sk = d2.d_date_sk
        WHERE d2.d_year = 1998
    )
),
web_agg AS (
    SELECT
        'Web' AS source_type,
        ws_site.web_name AS entity_name,
        CASE WHEN ws_site.web_gmt_offset > 0 THEN 'East' ELSE 'West' END AS region,
        SUM(ws.ws_net_profit) AS total_profit,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        AVG(ws.ws_net_profit) AS avg_profit_per_sale,
        ROW_NUMBER() OVER (
            PARTITION BY CASE WHEN ws_site.web_gmt_offset > 0 THEN 'East' ELSE 'West' END
            ORDER BY SUM(ws.ws_net_profit) DESC
        ) AS rank_in_region
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN web_site ws_site ON ws.ws_web_site_sk = ws_site.web_site_sk
    WHERE d.d_year = 1998
      AND ws_site.web_name LIKE '%Shop%'
      AND regexp_extract(ws_site.web_name, '^([A-Za-z]+)', 1) = 'Online'
      AND EXISTS (
          SELECT 1 FROM call_center cc2 WHERE cc2.cc_state = ws_site.web_state
      )
    GROUP BY ws_site.web_name, ws_site.web_gmt_offset
    HAVING SUM(ws.ws_net_profit) > 0
)
,
combined AS (
    SELECT
        source_type,
        entity_name,
        region,
        total_profit,
        total_sales,
        avg_profit_per_sale,
        rank_in_region
    FROM catalog_agg
    WHERE rank_in_region <= 5
    UNION ALL
    SELECT
        source_type,
        entity_name,
        region,
        total_profit,
        total_sales,
        avg_profit_per_sale,
        rank_in_region
    FROM web_agg
    WHERE rank_in_region <= 5
)
SELECT
    source_type,
    entity_name,
    region,
    total_profit,
    total_sales,
    avg_profit_per_sale,
    rank_in_region,
    total_profit - (
        SELECT AVG(c.cs_net_profit)
        FROM catalog_sales c
        JOIN date_dim d ON c.cs_sold_date_sk = d.d_date_sk
        WHERE d.d_year = 1998
    ) AS profit_vs_overall_avg,
    CASE WHEN total_profit < (
        SELECT MAX(tp.total_profit)
        FROM (
            SELECT total_profit FROM catalog_agg
            UNION ALL
            SELECT total_profit FROM web_agg
        ) tp
    ) THEN TRUE ELSE FALSE END AS has_higher_profit_entity
FROM combined
ORDER BY total_profit DESC
