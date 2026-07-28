WITH filtered_pages AS (
    SELECT
        cp.cp_catalog_page_sk,
        cp.cp_department,
        cp.cp_type,
        cp.cp_description,
        cp.cp_catalog_number,
        cp.cp_catalog_page_number
    FROM catalog_page cp
    WHERE regexp_like(cp.cp_description, '(?i)discount')
      AND cp.cp_type LIKE 'A%'
),
page_returns AS (
    SELECT
        cr.cr_catalog_page_sk,
        SUM(cr.cr_return_amount) AS total_return_amount,
        SUM(cr.cr_net_loss) AS total_net_loss,
        COUNT(*) AS return_cnt
    FROM catalog_returns cr
    GROUP BY cr.cr_catalog_page_sk
),
joined AS (
    SELECT
        fp.cp_catalog_page_sk,
        fp.cp_department,
        fp.cp_type,
        fp.cp_description,
        pr.total_return_amount,
        pr.total_net_loss,
        pr.return_cnt,
        CASE WHEN pr.total_return_amount > 5000 THEN 'High' ELSE 'Low' END AS loss_category
    FROM filtered_pages fp
    LEFT JOIN page_returns pr
        ON fp.cp_catalog_page_sk = pr.cr_catalog_page_sk
    WHERE NOT EXISTS (
        SELECT 1
        FROM catalog_returns cr2
        WHERE cr2.cr_catalog_page_sk = fp.cp_catalog_page_sk
          AND cr2.cr_return_amount > 1000
    )
)
SELECT
    DISTINCT j.cp_department,
    j.cp_type,
    j.loss_category,
    j.total_return_amount,
    j.total_net_loss,
    j.return_cnt,
    ROW_NUMBER() OVER (PARTITION BY j.cp_department ORDER BY j.total_return_amount DESC) AS dept_rank
FROM joined j
ORDER BY j.total_return_amount DESC
LIMIT 100
