WITH sales_agg AS (
    SELECT
        s.s_store_sk,
        s.s_store_name,
        d.d_year,
        SUM(ss.ss_net_profit) AS total_net_profit,
        COUNT(*) AS txn_count,
        CASE WHEN SUM(ss.ss_net_profit) > 10000 THEN 'High' ELSE 'Medium' END AS profit_category
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    WHERE d.d_year = 2001                     -- predicate 1
      AND hd.hd_income_band_sk BETWEEN 5 AND 10   -- predicate 2
      AND s.s_state = 'CA'                     -- predicate 3
      AND ss.ss_quantity > 1                  -- predicate 4
      AND ss.ss_wholesale_cost > 10           -- predicate 5
    GROUP BY s.s_store_sk, s.s_store_name, d.d_year
),
store_without_sales AS (
    SELECT s_store_sk FROM store
    EXCEPT
    SELECT ss_store_sk FROM store_sales
),
web_page_info AS (
    SELECT
        wp.wp_web_page_sk,
        wp.wp_url,
        wp.wp_type,
        d_creation.d_year AS creation_year,
        d_creation.d_date_sk AS creation_date_sk,
        d_access.d_year AS access_year,
        d_access.d_date_sk AS access_date_sk,
        MAP(ARRAY['url','type'], ARRAY[wp.wp_url, wp.wp_type]) AS url_type_map
    FROM web_page wp
    JOIN date_dim d_creation ON wp.wp_creation_date_sk = d_creation.d_date_sk
    JOIN date_dim d_access   ON wp.wp_access_date_sk   = d_access.d_date_sk
    WHERE wp.wp_type = 'Home'                    -- predicate 6
      AND d_creation.d_year = 2001               -- predicate 7
      AND d_access.d_year   = 2001               -- predicate 8
),
expanded_wp AS (
    SELECT
        wpinfo.*, 
        kv.key,
        kv.value
    FROM web_page_info wpinfo
    CROSS JOIN UNNEST(wpinfo.url_type_map) AS kv(key, value)
)
SELECT
    s.s_store_name,
    s.s_city,
    s.s_state,
    sa.d_year,
    sa.total_net_profit,
    sa.txn_count,
    sa.profit_category,
    ROW_NUMBER() OVER (PARTITION BY sa.d_year ORDER BY sa.total_net_profit DESC) AS profit_rank,
    ew.key AS map_key,
    ew.value AS map_value
FROM store s
FULL OUTER JOIN sales_agg sa ON s.s_store_sk = sa.s_store_sk               -- full outer join as required
LEFT JOIN expanded_wp ew ON s.s_closed_date_sk = ew.creation_date_sk          -- join via date_dim key
WHERE s.s_store_sk NOT IN (SELECT s_store_sk FROM store_without_sales)       -- anti‑semi‑join
  AND s.s_store_sk IS NOT NULL                                               -- keep only real stores after FULL OUTER
ORDER BY sa.total_net_profit DESC
OFFSET 0 FETCH NEXT 100 ROWS ONLY
