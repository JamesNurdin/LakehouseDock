WITH avg_net_loss AS (
    SELECT AVG(net_loss) AS avg_loss
    FROM (
        SELECT cr.cr_net_loss AS net_loss FROM tpcds.catalog_returns cr
        UNION ALL
        SELECT sr.sr_net_loss AS net_loss FROM tpcds.store_returns sr
    )
)
SELECT
    i.i_item_id,
    i.i_product_name,
    'Catalog' AS return_channel,
    cr.cr_return_quantity AS return_quantity,
    cr.cr_net_loss AS net_loss,
    CASE
        WHEN cr.cr_net_loss > (SELECT avg_loss FROM avg_net_loss) THEN 'Above Avg'
        ELSE 'Below Avg'
    END AS loss_category,
    cc.cc_name AS call_center_name
FROM tpcds.catalog_returns cr
JOIN tpcds.item i ON cr.cr_item_sk = i.i_item_sk
JOIN tpcds.call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
JOIN tpcds.reason r ON cr.cr_reason_sk = r.r_reason_sk
WHERE r.r_reason_desc LIKE '%damaged%'
  AND EXISTS (
      SELECT 1 FROM tpcds.catalog_page cp
      WHERE cp.cp_catalog_page_sk = cr.cr_catalog_page_sk
        AND cp.cp_type = 'online'
  )
UNION ALL
SELECT
    i.i_item_id,
    i.i_product_name,
    'Store' AS return_channel,
    sr.sr_return_quantity AS return_quantity,
    sr.sr_net_loss AS net_loss,
    CASE
        WHEN sr.sr_net_loss > (SELECT avg_loss FROM avg_net_loss) THEN 'Above Avg'
        ELSE 'Below Avg'
    END AS loss_category,
    CAST(NULL AS varchar) AS call_center_name
FROM tpcds.store_returns sr
JOIN tpcds.item i ON sr.sr_item_sk = i.i_item_sk
JOIN tpcds.reason r ON sr.sr_reason_sk = r.r_reason_sk
WHERE r.r_reason_desc LIKE '%damaged%'
ORDER BY net_loss DESC
