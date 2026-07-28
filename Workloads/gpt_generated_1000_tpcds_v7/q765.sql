WITH catalog AS (
    SELECT
        d.d_year,
        r.r_reason_desc,
        regexp_extract(r.r_reason_desc, '(Damaged|Defect)', 1) AS matched_reason,
        SUM(cr.cr_net_loss) AS catalog_net_loss
    FROM catalog_returns cr
    JOIN date_dim d
        ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN reason r
        ON cr.cr_reason_sk = r.r_reason_sk
    WHERE d.d_year BETWEEN 2000 AND 2002
      AND regexp_like(r.r_reason_desc, '(?i)damaged|defect')
    GROUP BY
        d.d_year,
        r.r_reason_desc,
        regexp_extract(r.r_reason_desc, '(Damaged|Defect)', 1)
),
web AS (
    SELECT
        d.d_year,
        r.r_reason_desc,
        regexp_extract(r.r_reason_desc, '(Damaged|Defect)', 1) AS matched_reason,
        regexp_extract(wp.wp_url, '/products/([^/]+)/', 1) AS product_id,
        SUM(wr.wr_net_loss) AS web_net_loss
    FROM web_returns wr
    JOIN date_dim d
        ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN reason r
        ON wr.wr_reason_sk = r.r_reason_sk
    JOIN web_page wp
        ON wr.wr_web_page_sk = wp.wp_web_page_sk
    WHERE d.d_year BETWEEN 2000 AND 2002
      AND regexp_like(r.r_reason_desc, '(?i)damaged|defect')
      AND wp.wp_url LIKE '%/products/%'
      AND regexp_like(wp.wp_url, '\\.html$')
    GROUP BY
        d.d_year,
        r.r_reason_desc,
        regexp_extract(r.r_reason_desc, '(Damaged|Defect)', 1),
        regexp_extract(wp.wp_url, '/products/([^/]+)/', 1)
)
SELECT
    COALESCE(c.d_year, w.d_year) AS year,
    COALESCE(c.r_reason_desc, w.r_reason_desc) AS reason_description,
    COALESCE(c.matched_reason, w.matched_reason) AS matched_pattern,
    CONCAT('Reason: ', COALESCE(c.matched_reason, w.matched_reason)) AS reason_label,
    SUM(c.catalog_net_loss) AS total_catalog_loss,
    SUM(w.web_net_loss) AS total_web_loss,
    SUM(COALESCE(c.catalog_net_loss, 0) + COALESCE(w.web_net_loss, 0)) AS total_combined_loss
FROM catalog c
FULL OUTER JOIN web w
    ON c.d_year = w.d_year
   AND c.r_reason_desc = w.r_reason_desc
   AND c.matched_reason = w.matched_reason
GROUP BY
    COALESCE(c.d_year, w.d_year),
    COALESCE(c.r_reason_desc, w.r_reason_desc),
    COALESCE(c.matched_reason, w.matched_reason),
    CONCAT('Reason: ', COALESCE(c.matched_reason, w.matched_reason))
ORDER BY year, total_combined_loss DESC
