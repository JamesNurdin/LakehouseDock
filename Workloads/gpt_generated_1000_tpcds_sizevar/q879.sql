WITH recent_dates AS (
        SELECT d_date_sk,
               d_date
        FROM   date_dim
        WHERE  d_year = 2001
          AND  d_moy IN (4, 5, 6)
    ),
    aggregated_returns AS (
        SELECT
            dr.d_date                                 AS return_date,
            wp.wp_url,
            r.r_reason_desc,
            SUM(wr.wr_return_amt)                     AS total_return_amount,
            COUNT(*)                                   AS return_cnt
        FROM   web_returns wr
        JOIN   recent_dates dr ON wr.wr_returned_date_sk = dr.d_date_sk
        JOIN   web_page wp      ON wr.wr_web_page_sk = wp.wp_web_page_sk
        JOIN   reason r         ON wr.wr_reason_sk = r.r_reason_sk
        WHERE  wp.wp_autogen_flag = 'N'
        GROUP BY dr.d_date, wp.wp_url, r.r_reason_desc

        UNION ALL

        SELECT
            dr.d_date                                 AS return_date,
            wp.wp_url,
            r.r_reason_desc,
            SUM(wr.wr_return_amt)                     AS total_return_amount,
            COUNT(*)                                   AS return_cnt
        FROM   web_returns wr
        JOIN   recent_dates dr ON wr.wr_returned_date_sk = dr.d_date_sk
        JOIN   reason r         ON wr.wr_reason_sk = r.r_reason_sk
        LEFT   JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
                                   AND wp.wp_autogen_flag = 'Y'
        WHERE  EXISTS (
                   SELECT 1
                   FROM   web_page wp2
                   WHERE  wp2.wp_web_page_sk = wp.wp_web_page_sk
                     AND  wp2.wp_char_count > 1000
               )
        GROUP BY dr.d_date, wp.wp_url, r.r_reason_desc
    )
SELECT
    COALESCE(ar.return_date, d.d_date)                         AS return_date,
    ar.wp_url,
    COALESCE(ar.r_reason_desc, r.r_reason_desc)               AS reason_desc,
    ar.total_return_amount,
    ar.return_cnt,
    (SELECT COUNT(DISTINCT wp_web_page_sk) FROM web_page)    AS total_distinct_pages
FROM   aggregated_returns ar
FULL   OUTER JOIN reason r ON ar.r_reason_desc = r.r_reason_desc
LEFT   JOIN date_dim d ON ar.return_date = d.d_date
WHERE  (ar.total_return_amount > 0 OR r.r_reason_desc IS NOT NULL)
ORDER  BY return_date DESC NULLS LAST,
          total_return_amount DESC
OFFSET 0
LIMIT  100
