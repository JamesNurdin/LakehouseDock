WITH base AS (
    SELECT
        cc.cc_division_name AS division,
        w.w_warehouse_name AS warehouse,
        cp.cp_department AS department,
        d.d_year AS year,
        SUM(cr.cr_return_amount) AS total_return_amount,
        SUM(cr.cr_return_quantity) AS total_return_qty,
        AVG(inv.inv_quantity_on_hand) AS avg_inventory_on_hand,
        SUM(CASE WHEN cr.cr_return_amount > 1000 THEN 1 ELSE 0 END) AS high_return_cnt
    FROM catalog_returns cr
    JOIN date_dim d
        ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN call_center cc
        ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp
        ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN warehouse w
        ON cr.cr_warehouse_sk = w.w_warehouse_sk
    LEFT JOIN inventory inv
        ON inv.inv_warehouse_sk = w.w_warehouse_sk
        AND inv.inv_date_sk = d.d_date_sk
    WHERE
        d.d_year = 2001
        AND cc.cc_state = 'CA'
        AND w.w_state = 'CA'
        AND cp.cp_department = 'Sports'
        AND cr.cr_return_amount IS NOT NULL
        AND cr.cr_return_quantity > 0
        AND EXISTS (
            SELECT 1
            FROM web_site ws
            WHERE ws.web_city = cc.cc_city
              AND ws.web_mkt_class LIKE '%funds%'
              AND ws.web_open_date_sk = d.d_date_sk
        )
        AND EXISTS (
            SELECT 1
            FROM web_page wp
            WHERE wp.wp_creation_date_sk = d.d_date_sk
              AND wp.wp_autogen_flag = 'N'
              AND wp.wp_url LIKE '%example%'
        )
    GROUP BY
        cc.cc_division_name,
        w.w_warehouse_name,
        cp.cp_department,
        d.d_year
)
SELECT
    division,
    warehouse,
    department,
    year,
    total_return_amount,
    total_return_qty,
    avg_inventory_on_hand,
    high_return_cnt,
    CASE
        WHEN high_return_cnt > 10 THEN 'Many High Returns'
        ELSE 'Few High Returns'
    END AS return_level,
    total_return_amount / NULLIF(total_return_qty, 0) AS avg_return_per_item
FROM base
WHERE total_return_amount > 5000
ORDER BY total_return_amount DESC
LIMIT 100
