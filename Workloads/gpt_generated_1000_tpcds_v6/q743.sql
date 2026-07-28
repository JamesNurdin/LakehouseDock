WITH store_part AS (
    SELECT
        d1.d_year,
        p.p_promo_name,
        SUM(sr.sr_return_amt) AS total_store_return_amt,
        COUNT(*) AS store_return_cnt,
        CASE WHEN p.p_discount_active = 'Y' THEN 'Active' ELSE 'Inactive' END AS promo_status
    FROM store_returns sr
    JOIN date_dim d1 ON sr.sr_returned_date_sk = d1.d_date_sk
    JOIN promotion p ON p.p_start_date_sk = d1.d_date_sk
    JOIN catalog_page cp ON cp.cp_start_date_sk = d1.d_date_sk
    JOIN web_site ws ON ws.web_open_date_sk = d1.d_date_sk
    JOIN web_page wp ON wp.wp_creation_date_sk = d1.d_date_sk
    WHERE d1.d_year = 2000
      AND p.p_promo_name = 'Promotion A'
      AND ws.web_manager = 'Herbert Hawes'
    GROUP BY d1.d_year,
             p.p_promo_name,
             CASE WHEN p.p_discount_active = 'Y' THEN 'Active' ELSE 'Inactive' END
),
web_part AS (
    SELECT
        d2.d_year,
        p2.p_promo_name,
        SUM(wr.wr_return_amt) AS total_web_return_amt,
        COUNT(*) AS web_return_cnt,
        CASE WHEN p2.p_discount_active = 'Y' THEN 'Active' ELSE 'Inactive' END AS promo_status
    FROM web_returns wr
    JOIN date_dim d2 ON wr.wr_returned_date_sk = d2.d_date_sk
    JOIN promotion p2 ON p2.p_start_date_sk = d2.d_date_sk
    JOIN web_page wp2 ON wr.wr_web_page_sk = wp2.wp_web_page_sk
    JOIN catalog_page cp2 ON cp2.cp_end_date_sk = d2.d_date_sk
    JOIN web_site ws2 ON ws2.web_close_date_sk = d2.d_date_sk
    WHERE d2.d_year = 2000
      AND p2.p_promo_name = 'Promotion B'
      AND ws2.web_manager = 'Harold Wilson'
    GROUP BY d2.d_year,
             p2.p_promo_name,
             CASE WHEN p2.p_discount_active = 'Y' THEN 'Active' ELSE 'Inactive' END
)
SELECT *
FROM (
    SELECT
        d_year,
        p_promo_name,
        total_store_return_amt,
        store_return_cnt,
        promo_status,
        CAST(NULL AS decimal(7,2)) AS total_web_return_amt,
        CAST(NULL AS integer) AS web_return_cnt,
        ROW_NUMBER() OVER (PARTITION BY d_year ORDER BY total_store_return_amt DESC) AS rn
    FROM store_part
    UNION ALL
    SELECT
        d_year,
        p_promo_name,
        CAST(NULL AS decimal(7,2)) AS total_store_return_amt,
        CAST(NULL AS integer) AS store_return_cnt,
        promo_status,
        total_web_return_amt,
        web_return_cnt,
        ROW_NUMBER() OVER (PARTITION BY d_year ORDER BY total_web_return_amt DESC) AS rn
    FROM web_part
) combined
ORDER BY d_year, rn
LIMIT 100
