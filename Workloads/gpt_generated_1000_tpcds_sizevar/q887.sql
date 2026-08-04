WITH
    promo_dates AS (
        SELECT p_start_date_sk AS date_sk
        FROM promotion
    ),
    web_dates AS (
        SELECT wp_creation_date_sk AS date_sk
        FROM web_page
    ),
    common_dates AS (
        SELECT date_sk FROM promo_dates
        INTERSECT
        SELECT date_sk FROM web_dates
    ),
    full_cc_date AS (
        SELECT
            cc.cc_call_center_id,
            d.d_date_sk,
            cc.cc_name,
            cc.cc_gmt_offset
        FROM call_center cc
        FULL OUTER JOIN date_dim d
            ON cc.cc_closed_date_sk = d.d_date_sk
    ),
    base_join AS (
        SELECT
            cc.cc_call_center_id,
            cc.cc_name,
            cc.cc_gmt_offset,
            d.d_year,
            d.d_quarter_seq,
            p.p_promo_id,
            p.p_cost,
            p.p_channel_demo,
            wp.wp_web_page_id,
            wp.wp_image_count,
            wp.wp_autogen_flag,
            d.d_date_sk
        FROM date_dim d
        LEFT JOIN call_center cc
            ON cc.cc_open_date_sk = d.d_date_sk
        LEFT JOIN promotion p
            ON p.p_start_date_sk = d.d_date_sk
        LEFT JOIN web_page wp
            ON wp.wp_creation_date_sk = d.d_date_sk
        WHERE d.d_current_year = 'Y'
          AND p.p_cost > 500
          AND wp.wp_image_count >= 3
    ),
    base_with_lateral AS (
        SELECT
            bj.*,
            lt.high_cost_cnt,
            fcd.cc_name        AS full_cc_name,
            fcd.cc_gmt_offset  AS full_cc_offset
        FROM base_join bj
        CROSS JOIN LATERAL (
            SELECT COUNT(*) AS high_cost_cnt
            FROM promotion p2
            WHERE p2.p_start_date_sk = bj.d_date_sk
              AND p2.p_cost > 1000
        ) lt
        LEFT JOIN full_cc_date fcd
            ON fcd.cc_call_center_id = bj.cc_call_center_id
           AND fcd.d_date_sk = bj.d_date_sk
        WHERE bj.d_date_sk IN (SELECT date_sk FROM common_dates)
    )
SELECT
    COALESCE(bwl.cc_call_center_id, 'ALL')                     AS call_center_id,
    bwl.d_year,
    bwl.d_quarter_seq,
    SUM(bwl.p_cost)                                            AS total_promo_cost,
    COUNT(DISTINCT bwl.wp_web_page_id)                         AS distinct_pages,
    AVG(CASE WHEN bwl.wp_autogen_flag = 'Y' THEN 1 ELSE 0 END) AS auto_page_ratio,
    SUM(bwl.high_cost_cnt)                                     AS total_high_cost_promos,
    MAX(CASE WHEN COALESCE(bwl.full_cc_offset, bwl.cc_gmt_offset) > 0 THEN 'East' ELSE 'West' END) AS region_flag,
    GROUPING(bwl.cc_call_center_id)                            AS grp_cc,
    GROUPING(bwl.d_year)                                       AS grp_year,
    GROUPING(bwl.d_quarter_seq)                                AS grp_quarter
FROM base_with_lateral bwl
WHERE bwl.p_channel_demo = 'N'
  AND COALESCE(bwl.full_cc_offset, bwl.cc_gmt_offset) BETWEEN -5.00 AND 5.00
  AND bwl.d_quarter_seq IN (14, 16, 19)
GROUP BY GROUPING SETS (
    (bwl.cc_call_center_id, bwl.d_year, bwl.d_quarter_seq),
    (bwl.d_year, bwl.d_quarter_seq),
    ()
)
ORDER BY total_promo_cost DESC
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY
