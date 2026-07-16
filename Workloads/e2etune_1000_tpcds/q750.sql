WITH website_market_agg AS (
    SELECT
        web_mkt_id,
        COUNT(DISTINCT web_site_sk) AS website_cnt,
        AVG(web_gmt_offset) AS avg_gmt_offset,
        MAX(web_tax_percentage) AS max_tax_pct
    FROM web_site
    WHERE web_state = 'CA'
    GROUP BY web_mkt_id
),
store_closed_time AS (
    SELECT
        s.s_store_sk,
        s.s_state,
        s.s_floor_space,
        s.s_tax_percentage,
        s.s_manager,
        s.s_hours,
        s.s_market_id,
        t.t_hour AS closed_hour
    FROM store s
    LEFT JOIN time_dim t
        ON s.s_closed_date_sk = t.t_time_sk
    WHERE s.s_hours LIKE '8AM-%'
      AND s.s_manager IN ('William Ward', 'Scott Smith')
      AND (t.t_hour IS NULL OR t.t_hour BETWEEN 9 AND 18)
),
state_agg AS (
    SELECT
        sc.s_state,
        COUNT(DISTINCT sc.s_store_sk) AS store_cnt,
        SUM(sc.s_floor_space) AS total_floor_space,
        AVG(sc.s_tax_percentage) AS avg_store_tax,
        SUM(COALESCE(wma.website_cnt, 0)) AS total_websites,
        AVG(COALESCE(wma.avg_gmt_offset, 0)) AS avg_market_gmt_offset,
        MIN(sc.closed_hour) AS earliest_closed_hour,
        MAX(sc.closed_hour) AS latest_closed_hour
    FROM store_closed_time sc
    LEFT JOIN website_market_agg wma
        ON sc.s_market_id = wma.web_mkt_id
    GROUP BY sc.s_state
    HAVING COUNT(DISTINCT sc.s_store_sk) >= 3
)
SELECT
    s.s_state,
    s.store_cnt,
    s.total_floor_space,
    s.avg_store_tax,
    s.total_websites,
    s.avg_market_gmt_offset,
    s.earliest_closed_hour,
    s.latest_closed_hour,
    RANK() OVER (ORDER BY s.total_floor_space DESC) AS state_floor_space_rank
FROM state_agg s
ORDER BY s.total_floor_space DESC
LIMIT 20
