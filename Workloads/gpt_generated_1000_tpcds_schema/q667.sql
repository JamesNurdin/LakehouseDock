WITH sel1 AS (
    SELECT
        wp.wp_web_page_id,
        r.r_reason_desc,
        wr.wr_return_amt,
        wr.wr_return_quantity,
        (SELECT COUNT(*) FROM web_returns wrc WHERE wrc.wr_reason_sk = wr.wr_reason_sk) AS reason_return_cnt,
        CAST(NULL AS varchar) AS page_attr
    FROM web_returns wr
    RIGHT JOIN web_page wp
        ON wr.wr_web_page_sk = wp.wp_web_page_sk
    LEFT JOIN reason r
        ON wr.wr_reason_sk = r.r_reason_sk
    WHERE wp.wp_rec_end_date = DATE '2001-09-02'
      AND wr.wr_return_ship_cost > 30
      AND NOT EXISTS (
          SELECT 1 FROM reason r2
          WHERE r2.r_reason_sk = wr.wr_reason_sk
            AND r2.r_reason_desc LIKE '%duplicate%'
      )
),
sel2 AS (
    SELECT
        wp2.wp_web_page_id,
        r2.r_reason_desc,
        wr2.wr_return_amt,
        wr2.wr_return_quantity,
        (SELECT COUNT(*) FROM web_returns wrc2 WHERE wrc2.wr_reason_sk = wr2.wr_reason_sk) AS reason_return_cnt,
        t.page_attr
    FROM web_returns wr2
    RIGHT JOIN web_page wp2
        ON wr2.wr_web_page_sk = wp2.wp_web_page_sk
    LEFT JOIN reason r2
        ON wr2.wr_reason_sk = r2.r_reason_sk
    CROSS JOIN UNNEST(ARRAY[wp2.wp_url, wp2.wp_type]) AS t(page_attr)
    WHERE wp2.wp_rec_start_date = DATE '1999-09-04'
      AND wr2.wr_return_ship_cost < 20
)
SELECT *
FROM (
    SELECT * FROM sel1
    UNION
    SELECT * FROM sel2
) AS u
ORDER BY u.wr_return_amt DESC
OFFSET 10
LIMIT 100
