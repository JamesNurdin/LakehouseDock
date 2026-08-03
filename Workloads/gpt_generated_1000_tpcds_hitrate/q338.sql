WITH filtered_store_returns AS (
    SELECT
        sr.sr_returned_date_sk,
        d.d_year,
        sr.sr_store_sk,
        s.s_store_name,
        sr.sr_item_sk,
        i.i_product_name,
        sr.sr_return_quantity,
        sr.sr_return_amt,
        sr.sr_net_loss
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    WHERE sr.sr_store_sk IN (
        SELECT s2.s_store_sk FROM store s2 WHERE s2.s_state = 'CA'
    )
      AND d.d_year = 2001
)

SELECT
    d_year AS return_year,
    'Store' AS source,
    s_store_name AS location_name,
    i_product_name AS product_name,
    sr_return_quantity AS return_qty,
    sr_return_amt AS return_amount,
    CASE WHEN sr_net_loss > (SELECT avg(sr_net_loss) FROM store_returns) THEN 'High' ELSE 'Normal' END AS loss_category
FROM filtered_store_returns

UNION ALL

SELECT
    d.d_year AS return_year,
    'Catalog' AS source,
    cc.cc_name AS location_name,
    i.i_product_name AS product_name,
    cr.cr_return_quantity AS return_qty,
    cr.cr_return_amount AS return_amount,
    CASE WHEN cr.cr_net_loss > (SELECT avg(cr_net_loss) FROM catalog_returns) THEN 'High' ELSE 'Normal' END AS loss_category
FROM catalog_returns cr
JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
JOIN item i ON cr.cr_item_sk = i.i_item_sk
WHERE EXISTS (
    SELECT 1 FROM promotion p
    WHERE p.p_item_sk = cr.cr_item_sk
      AND p.p_start_date_sk = cr.cr_returned_date_sk
)
  AND d.d_year = 2001

ORDER BY return_year DESC, source, loss_category
LIMIT 100
