WITH sales_agg AS (
    SELECT
        s.s_store_id AS entity_id,
        s.s_store_name AS entity_name,
        s.s_state AS region,
        d.d_year AS year,
        SUM(ss.ss_net_paid) AS total_sales,
        SUM(ss.ss_net_profit) AS total_profit
    FROM store_sales ss
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE s.s_store_name LIKE '%Store%'
      AND regexp_like(s.s_city, '^[A-Z][a-z]+$')
    GROUP BY s.s_store_id, s.s_store_name, s.s_state, d.d_year
),
returns_agg AS (
    SELECT
        cc.cc_call_center_id AS entity_id,
        cc.cc_name AS entity_name,
        cc.cc_state AS region,
        d.d_year AS year,
        SUM(cr.cr_return_amount) AS total_sales,
        SUM(cr.cr_net_loss) AS total_profit
    FROM catalog_returns cr
    JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    WHERE regexp_like(cc.cc_street_type, '^R')
    GROUP BY cc.cc_call_center_id, cc.cc_name, cc.cc_state, d.d_year
),
union_data AS (
    SELECT 'store' AS entity_type, entity_id, entity_name, region, year, total_sales, total_profit
    FROM sales_agg
    UNION
    SELECT 'call_center' AS entity_type, entity_id, entity_name, region, year, total_sales, total_profit
    FROM returns_agg
)
SELECT
    u.entity_type,
    u.entity_id,
    u.entity_name,
    u.region,
    u.year,
    u.total_sales,
    u.total_profit,
    ROW_NUMBER() OVER (PARTITION BY u.region ORDER BY u.total_profit DESC) AS profit_rank,
    concat(substr(u.entity_name, 1, 3), '-', u.region) AS name_region_code,
    (
        SELECT SUM(cr2.cr_return_amount)
        FROM catalog_returns cr2
        JOIN call_center cc2 ON cr2.cr_call_center_sk = cc2.cc_call_center_sk
        JOIN date_dim d2 ON cr2.cr_returned_date_sk = d2.d_date_sk
        WHERE d2.d_year = u.year
          AND cc2.cc_state = u.region
    ) AS state_return_total
FROM union_data u
WHERE u.total_sales > 1000
ORDER BY profit_rank ASC, u.total_profit DESC
OFFSET 10 LIMIT 100
