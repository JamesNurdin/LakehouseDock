WITH returns_base AS (
    SELECT
        cr.cr_net_loss,
        dd.d_year,
        i.i_item_desc,
        cp.cp_description,
        w.w_city,
        r.r_reason_desc
    FROM catalog_returns cr
    JOIN date_dim dd ON cr.cr_returned_date_sk = dd.d_date_sk
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    WHERE dd.d_year = 2001
      AND regexp_like(r.r_reason_desc, '(?i)damaged|defective')
      AND cp.cp_description LIKE 'Prom%'
)
SELECT
    w_city,
    regexp_extract(i_item_desc, 'brand ([A-Za-z]+)', 1) AS brand_extracted,
    COUNT(*) AS num_returns,
    SUM(cr_net_loss) AS total_net_loss,
    CASE WHEN SUM(cr_net_loss) > 10000 THEN 'High' ELSE 'Medium' END AS loss_category,
    MIN(SUBSTRING(cp_description, 1, 15)) AS sample_page_prefix
FROM returns_base
GROUP BY
    w_city,
    regexp_extract(i_item_desc, 'brand ([A-Za-z]+)', 1)
ORDER BY total_net_loss DESC
LIMIT 100
