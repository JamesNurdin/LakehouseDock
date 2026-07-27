WITH joined_data AS (
    SELECT
        cr.cr_return_amount,
        cr.cr_return_quantity,
        cr.cr_reason_sk,
        r.r_reason_desc,
        d.d_year,
        d.d_quarter_seq,
        cc.cc_name,
        cp.cp_department,
        inv.inv_quantity_on_hand,
        sr.sr_return_amt,
        sr.sr_return_quantity,
        wp.wp_type,
        ws.web_name
    FROM catalog_returns cr
    JOIN date_dim d
      ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN reason r
      ON cr.cr_reason_sk = r.r_reason_sk
    JOIN call_center cc
      ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp
      ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN inventory inv
      ON inv.inv_date_sk = d.d_date_sk
    LEFT JOIN store_returns sr
      ON sr.sr_returned_date_sk = d.d_date_sk
     AND sr.sr_reason_sk = r.r_reason_sk
    LEFT JOIN web_page wp
      ON wp.wp_creation_date_sk = d.d_date_sk
    LEFT JOIN web_site ws
      ON ws.web_open_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
      AND cc.cc_state = 'CA'
      AND r.r_reason_desc LIKE '%size%'
      AND cp.cp_department = 'Electronics'
      AND inv.inv_quantity_on_hand > 0
),
aggregated AS (
    SELECT
        r_reason_desc,
        d_year,
        d_quarter_seq,
        SUM(cr_return_amount) AS sum_catalog_return_amount,
        SUM(sr_return_amt) AS sum_store_return_amount,
        SUM(inv_quantity_on_hand) AS sum_inventory_qty,
        COUNT(DISTINCT web_name) AS distinct_web_sites
    FROM joined_data
    GROUP BY r_reason_desc, d_year, d_quarter_seq
    HAVING SUM(cr_return_amount) > 1000
)
SELECT
    a.r_reason_desc,
    a.d_year,
    a.d_quarter_seq,
    a.sum_catalog_return_amount,
    a.sum_store_return_amount,
    a.sum_inventory_qty,
    a.distinct_web_sites,
    (a.sum_catalog_return_amount + a.sum_store_return_amount) / NULLIF(a.sum_inventory_qty, 0) AS return_per_inventory
FROM aggregated a
WHERE a.distinct_web_sites > (
    SELECT COUNT(DISTINCT ws2.web_name)
    FROM web_site ws2
    WHERE ws2.web_open_date_sk = (
        SELECT MAX(d2.d_date_sk)
        FROM date_dim d2
        WHERE d2.d_year = 2001
    )
)
ORDER BY a.sum_catalog_return_amount DESC
LIMIT 10
