WITH joined_data AS (
    SELECT
        cc.cc_call_center_id,
        cc.cc_county,
        cc.cc_state,
        cc.cc_gmt_offset,
        cp.cp_catalog_page_id,
        cp.cp_catalog_number,
        cp.cp_catalog_page_number,
        wp.wp_web_page_id,
        wp.wp_char_count,
        wp.wp_link_count,
        wp.wp_url,
        d.d_date,
        d.d_year,
        d.d_month_seq,
        d.d_day_name
    FROM date_dim d
    LEFT JOIN call_center cc
        ON cc.cc_open_date_sk = d.d_date_sk
    LEFT JOIN catalog_page cp
        ON cp.cp_start_date_sk = d.d_date_sk
    LEFT JOIN web_page wp
        ON wp.wp_creation_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
      AND cc.cc_county IN ('Maverick County', 'Williamson County')
      AND cc.cc_street_type = 'Avenue'
      AND wp.wp_char_count BETWEEN 2000 AND 6000
      AND wp.wp_link_count >= 10
      AND cp.cp_catalog_page_number IN (3, 11, 17)
),
ranked AS (
    SELECT
        jd.*, 
        SUM(jd.wp_char_count) OVER (PARTITION BY jd.cc_county) AS total_char_per_county,
        RANK() OVER (PARTITION BY jd.cc_county ORDER BY jd.wp_char_count DESC) AS char_count_rank,
        ROW_NUMBER() OVER (PARTITION BY jd.cc_county ORDER BY jd.d_date) AS day_seq
    FROM joined_data jd
)
SELECT
    cc_county,
    cc_state,
    d_year,
    d_month_seq,
    cp_catalog_page_number,
    wp_char_count,
    wp_link_count,
    total_char_per_county,
    char_count_rank,
    day_seq
FROM ranked
WHERE char_count_rank <= 3
ORDER BY total_char_per_county DESC, cc_county
LIMIT 100
