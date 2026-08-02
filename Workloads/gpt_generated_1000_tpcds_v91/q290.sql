WITH page_stats AS (
    SELECT
        wp.wp_web_page_id,
        d.d_date_sk,
        d.d_year,
        d.d_quarter_name,
        SUM(wp.wp_link_count) AS total_links,
        AVG(wp.wp_max_ad_count) AS avg_max_ads,
        COUNT(*) AS page_views,
        CASE WHEN AVG(wp.wp_max_ad_count) > 2 THEN 'HighAd' ELSE 'LowAd' END AS ad_intensity
    FROM (SELECT * FROM web_page TABLESAMPLE BERNOULLI (10)) wp
    JOIN date_dim d
        ON wp.wp_creation_date_sk = d.d_date_sk
    WHERE wp.wp_link_count > 0
      AND wp.wp_max_ad_count >= 0
      AND d.d_year BETWEEN 1999 AND 2002
      AND d.d_quarter_name IN ('1900Q1', '1901Q2', '1902Q3')
      AND wp.wp_access_date_sk IS NOT NULL
      AND wp.wp_autogen_flag = 'N'
    GROUP BY wp.wp_web_page_id, d.d_date_sk, d.d_year, d.d_quarter_name
),

catalog_agg AS (
    SELECT
        cp.cp_department,
        d.d_date_sk,
        d.d_year,
        d.d_quarter_name,
        COUNT(*) AS catalog_page_cnt,
        AVG(cp.cp_catalog_number) AS avg_catalog_number
    FROM catalog_page cp
    JOIN date_dim d
        ON cp.cp_start_date_sk = d.d_date_sk
    WHERE cp.cp_department IS NOT NULL
      AND cp.cp_type = 'P'
      AND d.d_month_seq BETWEEN 1200 AND 1300
      AND cp.cp_catalog_number > 0
      AND cp.cp_description <> ''
      AND cp.cp_end_date_sk <= cp.cp_start_date_sk + 365
    GROUP BY cp.cp_department, d.d_date_sk, d.d_year, d.d_quarter_name
),

website_agg AS (
    SELECT
        ws.web_site_id,
        d.d_date_sk,
        d.d_year,
        d.d_quarter_name,
        COUNT(*) AS site_active_days,
        SUM(ws.web_gmt_offset) AS total_gmt_offset
    FROM web_site ws
    JOIN date_dim d
        ON ws.web_open_date_sk = d.d_date_sk
    WHERE ws.web_name IS NOT NULL
      AND ws.web_gmt_offset BETWEEN -5 AND 5
      AND d.d_year BETWEEN 1999 AND 2002
      AND ws.web_mkt_id IS NOT NULL
      AND ws.web_class IN ('A', 'B', 'C')
      AND ws.web_open_date_sk < ws.web_close_date_sk
    GROUP BY ws.web_site_id, d.d_date_sk, d.d_year, d.d_quarter_name
),

catalog_website_full AS (
    SELECT
        COALESCE(ca.d_date_sk, wa.d_date_sk) AS d_date_sk,
        COALESCE(ca.d_year, wa.d_year) AS d_year,
        COALESCE(ca.d_quarter_name, wa.d_quarter_name) AS d_quarter_name,
        ca.cp_department,
        wa.web_site_id,
        ca.catalog_page_cnt,
        wa.site_active_days,
        ca.avg_catalog_number,
        wa.total_gmt_offset
    FROM catalog_agg ca
    FULL OUTER JOIN website_agg wa
        ON ca.d_date_sk = wa.d_date_sk
)
SELECT
    cwf.d_year,
    cwf.d_quarter_name,
    cwf.cp_department,
    cwf.web_site_id,
    cwf.catalog_page_cnt,
    cwf.site_active_days,
    cwf.avg_catalog_number,
    cwf.total_gmt_offset,
    ps.wp_web_page_id,
    ps.total_links,
    ps.avg_max_ads,
    ps.page_views,
    ps.ad_intensity,
    ROW_NUMBER() OVER (PARTITION BY cwf.d_year, cwf.d_quarter_name ORDER BY ps.total_links DESC) AS link_rank,
    RANK() OVER (PARTITION BY cwf.d_year, cwf.d_quarter_name ORDER BY ps.avg_max_ads DESC) AS ad_rank
FROM catalog_website_full cwf
LEFT JOIN page_stats ps
    ON cwf.d_date_sk = ps.d_date_sk
WHERE (cwf.catalog_page_cnt IS NOT NULL OR cwf.site_active_days IS NOT NULL)
  AND (ps.total_links IS NOT NULL OR ps.page_views IS NOT NULL)
  AND cwf.d_year IS NOT NULL
  AND cwf.d_quarter_name IS NOT NULL
  AND (cwf.cp_department IS NOT NULL OR cwf.web_site_id IS NOT NULL)
ORDER BY cwf.d_year DESC, cwf.d_quarter_name, link_rank
LIMIT 100
