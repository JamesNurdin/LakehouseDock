WITH catalog_profit AS (
    SELECT
        cs.cs_call_center_sk,
        SUM(cs.cs_net_profit - COALESCE(cr.cr_net_loss, 0)) AS total_catalog_profit,
        COUNT(*) AS catalog_sales_cnt
    FROM
        catalog_sales cs
    LEFT JOIN
        catalog_returns cr
        ON cs.cs_item_sk = cr.cr_item_sk
           AND cs.cs_order_number = cr.cr_order_number
           AND cr.cr_call_center_sk = cs.cs_call_center_sk
    GROUP BY
        cs.cs_call_center_sk
),
store_profit AS (
    SELECT
        SUM(ss.ss_net_profit - COALESCE(sr.sr_net_loss, 0)) AS total_store_profit,
        COUNT(*) AS store_sales_cnt
    FROM
        store_sales ss
    LEFT JOIN
        store_returns sr
        ON ss.ss_item_sk = sr.sr_item_sk
           AND ss.ss_ticket_number = sr.sr_ticket_number
)
SELECT
    cc.cc_call_center_id,
    cc.cc_class,
    cc.cc_gmt_offset,
    cp.total_catalog_profit,
    cp.catalog_sales_cnt,
    sp.total_store_profit,
    sp.store_sales_cnt,
    (cp.total_catalog_profit + sp.total_store_profit) AS total_profit,
    (cp.total_catalog_profit + sp.total_store_profit) / NULLIF(cc.cc_sq_ft, 0) AS profit_per_sq_ft,
    RANK() OVER (ORDER BY (cp.total_catalog_profit + sp.total_store_profit) / NULLIF(cc.cc_sq_ft, 0) DESC) AS profit_rank
FROM
    call_center cc
JOIN
    catalog_profit cp
    ON cc.cc_call_center_sk = cp.cs_call_center_sk
CROSS JOIN
    store_profit sp
WHERE
    cc.cc_class = 'large'
    AND cc.cc_gmt_offset = -5.00
ORDER BY
    profit_per_sq_ft DESC
LIMIT 20
