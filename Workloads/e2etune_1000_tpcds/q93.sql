WITH monthly_returns AS (
    SELECT
        cp.cp_type,
        d_ret.d_year,
        d_ret.d_month_seq,
        SUM(cr.cr_net_loss) AS total_net_loss,
        AVG(cr.cr_return_quantity) AS avg_return_qty,
        COUNT(*) AS return_cnt,
        COUNT(DISTINCT cp.cp_catalog_page_id) AS distinct_pages
    FROM catalog_page cp
    JOIN catalog_returns cr
        ON cp.cp_catalog_page_sk = cr.cr_catalog_page_sk
    JOIN date_dim d_ret
        ON cr.cr_returned_date_sk = d_ret.d_date_sk
    WHERE cp.cp_type IN ('monthly', 'quarterly')
      AND cp.cp_catalog_number > 2
      AND d_ret.d_year BETWEEN 2020 AND 2022
    GROUP BY cp.cp_type, d_ret.d_year, d_ret.d_month_seq
),
monthly_web_pages AS (
    SELECT
        d_web.d_year,
        d_web.d_month_seq,
        COUNT(DISTINCT wp.wp_web_page_id) AS web_page_cnt
    FROM web_page wp
    JOIN date_dim d_web
        ON wp.wp_creation_date_sk = d_web.d_date_sk
    WHERE d_web.d_year BETWEEN 2020 AND 2022
    GROUP BY d_web.d_year, d_web.d_month_seq
)
SELECT
    mr.cp_type,
    mr.d_year,
    mr.d_month_seq,
    mr.total_net_loss,
    mr.avg_return_qty,
    mr.return_cnt,
    mr.distinct_pages,
    COALESCE(mw.web_page_cnt, 0) AS web_page_cnt,
    RANK() OVER (PARTITION BY mr.cp_type ORDER BY mr.total_net_loss DESC) AS loss_rank
FROM monthly_returns mr
LEFT JOIN monthly_web_pages mw
    ON mr.d_year = mw.d_year
   AND mr.d_month_seq = mw.d_month_seq
ORDER BY mr.cp_type, mr.total_net_loss DESC
LIMIT 200
