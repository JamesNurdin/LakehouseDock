WITH
store_ret AS (
    SELECT
        sr.sr_store_sk,
        dr.d_year,
        dr.d_moy,
        SUM(sr.sr_return_amt) AS store_return_amt,
        SUM(sr.sr_net_loss) AS store_net_loss,
        COUNT(*) AS store_return_cnt
    FROM store_returns sr
    JOIN date_dim dr
        ON sr.sr_returned_date_sk = dr.d_date_sk
    GROUP BY sr.sr_store_sk, dr.d_year, dr.d_moy
),
web_ret AS (
    SELECT
        wr.wr_web_page_sk,
        dw.d_year,
        dw.d_moy,
        SUM(wr.wr_return_amt) AS web_return_amt,
        SUM(wr.wr_net_loss) AS web_net_loss,
        COUNT(*) AS web_return_cnt
    FROM web_returns wr
    JOIN date_dim dw
        ON wr.wr_returned_date_sk = dw.d_date_sk
    GROUP BY wr.wr_web_page_sk, dw.d_year, dw.d_moy
)
SELECT
    CASE
        WHEN s.s_floor_space > 50000 THEN 'Large Store'
        WHEN s.s_floor_space > 20000 THEN 'Medium Store'
        ELSE 'Small Store'
    END AS store_size_category,
    sr.d_year AS return_year,
    sr.d_moy AS return_month,
    wp.wp_type,
    SUM(sr.store_return_amt) AS total_store_return_amt,
    SUM(wr.web_return_amt) AS total_web_return_amt,
    SUM(sr.store_net_loss) + SUM(wr.web_net_loss) AS total_combined_net_loss,
    SUM(sr.store_return_cnt) AS total_store_return_cnt,
    SUM(wr.web_return_cnt) AS total_web_return_cnt,
    COUNT(DISTINCT s.s_store_sk) AS distinct_store_cnt,
    COUNT(DISTINCT wp.wp_web_page_sk) AS distinct_web_page_cnt
FROM store s
JOIN store_ret sr ON sr.sr_store_sk = s.s_store_sk
JOIN date_dim ds ON s.s_closed_date_sk = ds.d_date_sk
JOIN web_ret wr ON wr.d_year = sr.d_year AND wr.d_moy = sr.d_moy
JOIN web_page wp ON wp.wp_web_page_sk = wr.wr_web_page_sk
JOIN date_dim d_creation ON wp.wp_creation_date_sk = d_creation.d_date_sk
JOIN date_dim d_access ON wp.wp_access_date_sk = d_access.d_date_sk
GROUP BY 1, 2, 3, 4
ORDER BY total_store_return_amt DESC
LIMIT 100
