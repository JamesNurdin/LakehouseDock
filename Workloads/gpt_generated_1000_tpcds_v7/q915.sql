WITH filtered_returns AS (
    SELECT
        cr.cr_order_number,
        cr.cr_catalog_page_sk,
        cr.cr_reason_sk,
        cr.cr_refunded_hdemo_sk,
        cr.cr_net_loss,
        cr.cr_return_quantity,
        cp.cp_department,
        cp.cp_catalog_page_id,
        cp.cp_description,
        r.r_reason_desc,
        ib.ib_lower_bound,
        ib.ib_upper_bound
    FROM catalog_returns cr
    JOIN catalog_sales cs
        ON cr.cr_order_number = cs.cs_order_number
    JOIN catalog_page cp
        ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN reason r
        ON cr.cr_reason_sk = r.r_reason_sk
    JOIN household_demographics hd
        ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE regexp_like(cp.cp_description, '[A-Z]{2}[0-9]{3}')
      AND r.r_reason_desc LIKE '%damaged%'
)
SELECT
    concat(cp_department, '-', substr(cp_catalog_page_id, 1, 5)) AS dept_page_key,
    regexp_extract(cp_catalog_page_id, '(\\d+)', 1) AS page_number,
    ib_lower_bound,
    ib_upper_bound,
    sum(cr_net_loss) AS total_net_loss,
    avg(cr_return_quantity) AS avg_return_qty
FROM filtered_returns
GROUP BY
    concat(cp_department, '-', substr(cp_catalog_page_id, 1, 5)),
    regexp_extract(cp_catalog_page_id, '(\\d+)', 1),
    ib_lower_bound,
    ib_upper_bound
ORDER BY total_net_loss DESC
LIMIT 20
