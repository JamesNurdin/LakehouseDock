WITH filtered_returns AS (
    SELECT
        wr.wr_returned_date_sk,
        dr.d_year,
        dr.d_month_seq,
        s.s_state,
        wr.wr_return_quantity,
        wr.wr_net_loss,
        wp.wp_url,
        wp.wp_type
    FROM web_returns wr
    JOIN date_dim dr ON wr.wr_returned_date_sk = dr.d_date_sk
    JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
    LEFT JOIN store s ON s.s_closed_date_sk = dr.d_date_sk
    WHERE regexp_like(wp.wp_url, '^https?://[^/]+/sale/')
      AND wp.wp_type LIKE 'product%'
)
SELECT
    dr.d_year,
    dr.d_month_seq,
    s.s_state,
    COUNT(*) AS return_count,
    SUM(wr.wr_return_quantity) AS total_quantity,
    SUM(wr.wr_net_loss) AS total_net_loss,
    CASE WHEN SUM(wr.wr_net_loss) > 0 THEN 'Loss' ELSE 'Gain' END AS net_loss_category,
    CONCAT(regexp_extract(wp.wp_url, '^https?://([^/]+)/', 1), ':', CAST(dr.d_month_seq AS VARCHAR)) AS domain_month
FROM web_returns wr
JOIN date_dim dr ON wr.wr_returned_date_sk = dr.d_date_sk
JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
LEFT JOIN store s ON s.s_closed_date_sk = dr.d_date_sk
WHERE regexp_like(wp.wp_url, '^https?://[^/]+/sale/')
  AND wp.wp_type LIKE 'product%'
GROUP BY
    dr.d_year,
    dr.d_month_seq,
    s.s_state,
    CONCAT(regexp_extract(wp.wp_url, '^https?://([^/]+)/', 1), ':', CAST(dr.d_month_seq AS VARCHAR))
ORDER BY
    dr.d_year DESC,
    dr.d_month_seq DESC,
    total_net_loss DESC
