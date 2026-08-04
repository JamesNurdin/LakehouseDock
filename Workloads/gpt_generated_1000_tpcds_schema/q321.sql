WITH
    agg_store_sales AS (
        SELECT
            ss_item_sk,
            SUM(ss_net_paid) AS total_net_paid,
            SUM(ss_quantity) AS total_qty,
            MIN(ss_sold_date_sk) AS min_sold_date_sk
        FROM store_sales
        WHERE ss_sold_date_sk BETWEEN 2415400 AND 2415600
        GROUP BY ss_item_sk
    ),
    computed_set AS (
        SELECT 1 AS const_val UNION ALL SELECT 2 UNION ALL SELECT 3
    ),
    reason_small AS (
        SELECT DISTINCT r_reason_sk, r_reason_desc
        FROM reason
        WHERE r_reason_sk IN (7, 8)
    )

SELECT DISTINCT
    i.i_brand,
    d_sales.d_year,
    r.r_reason_desc,
    agg.total_net_paid,
    agg.total_qty,
    COALESCE(SUM(sr.sr_net_loss), 0) AS store_return_loss,
    COALESCE(SUM(cr.cr_net_loss), 0) AS catalog_return_loss,
    COALESCE(SUM(wr.wr_net_loss), 0) AS web_return_loss,
    cs.const_val
FROM agg_store_sales agg
JOIN item i ON agg.ss_item_sk = i.i_item_sk
JOIN date_dim d_sales ON agg.min_sold_date_sk = d_sales.d_date_sk
LEFT JOIN store_returns sr ON sr.sr_item_sk = agg.ss_item_sk
LEFT JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
LEFT JOIN catalog_returns cr ON cr.cr_item_sk = agg.ss_item_sk
LEFT JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
LEFT JOIN web_returns wr ON wr.wr_item_sk = agg.ss_item_sk
CROSS JOIN reason_small rs
CROSS JOIN computed_set cs
WHERE EXISTS (
    SELECT 1
    FROM store_returns sr2
    WHERE sr2.sr_item_sk = agg.ss_item_sk
      AND sr2.sr_net_loss > 0
)
GROUP BY CUBE (i.i_brand, d_sales.d_year, r.r_reason_desc),
         agg.total_net_paid,
         agg.total_qty,
         cs.const_val
HAVING agg.total_net_paid > 0

UNION DISTINCT

SELECT DISTINCT
    i.i_brand,
    d_sales2.d_year,
    r.r_reason_desc,
    agg2.total_net_paid,
    agg2.total_qty,
    COALESCE(SUM(sr2.sr_net_loss), 0) AS store_return_loss,
    COALESCE(SUM(cr2.cr_net_loss), 0) AS catalog_return_loss,
    COALESCE(SUM(wr2.wr_net_loss), 0) AS web_return_loss,
    cs2.const_val
FROM (
        SELECT
            ss_item_sk,
            SUM(ss_net_paid) AS total_net_paid,
            SUM(ss_quantity) AS total_qty,
            MIN(ss_sold_date_sk) AS min_sold_date_sk
        FROM store_sales
        WHERE ss_sold_date_sk BETWEEN 2415601 AND 2415800
        GROUP BY ss_item_sk
     ) agg2
JOIN item i ON agg2.ss_item_sk = i.i_item_sk
JOIN date_dim d_sales2 ON agg2.min_sold_date_sk = d_sales2.d_date_sk
LEFT JOIN store_returns sr2 ON sr2.sr_item_sk = agg2.ss_item_sk
LEFT JOIN reason r ON sr2.sr_reason_sk = r.r_reason_sk
LEFT JOIN catalog_returns cr2 ON cr2.cr_item_sk = agg2.ss_item_sk
LEFT JOIN catalog_page cp2 ON cr2.cr_catalog_page_sk = cp2.cp_catalog_page_sk
LEFT JOIN web_returns wr2 ON wr2.wr_item_sk = agg2.ss_item_sk
CROSS JOIN reason_small rs
CROSS JOIN computed_set cs2
WHERE EXISTS (
    SELECT 1
    FROM store_returns sr2b
    WHERE sr2b.sr_item_sk = agg2.ss_item_sk
      AND sr2b.sr_net_loss > 0
)
GROUP BY CUBE (i.i_brand, d_sales2.d_year, r.r_reason_desc),
         agg2.total_net_paid,
         agg2.total_qty,
         cs2.const_val
HAVING agg2.total_net_paid > 0

ORDER BY total_net_paid DESC
LIMIT 100
