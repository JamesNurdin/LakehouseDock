WITH store_part AS (
    SELECT
        d.d_date AS return_date,
        i.i_item_id,
        i.i_product_name,
        sr.sr_net_loss AS net_loss,
        'store' AS source
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    WHERE d.d_year = 2001
      AND EXISTS (
          SELECT 1
          FROM promotion p
          WHERE p.p_item_sk = i.i_item_sk
            AND p.p_start_date_sk = d.d_date_sk
      )
),
catalog_part AS (
    SELECT
        d.d_date AS return_date,
        i.i_item_id,
        i.i_product_name,
        cr.cr_net_loss AS net_loss,
        'catalog' AS source
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
    WHERE d.d_year = 2001
      AND EXISTS (
          SELECT 1
          FROM promotion p
          WHERE p.p_item_sk = i.i_item_sk
            AND p.p_end_date_sk = d.d_date_sk
      )
),
combined AS (
    SELECT * FROM store_part
    UNION ALL
    SELECT * FROM catalog_part
)
SELECT
    c.return_date,
    c.i_item_id,
    c.i_product_name,
    c.net_loss,
    c.source,
    ROW_NUMBER() OVER (PARTITION BY c.source ORDER BY c.return_date) AS rn,
    (
        SELECT AVG(sr3.sr_net_loss)
        FROM store_returns sr3
        JOIN date_dim d3 ON sr3.sr_returned_date_sk = d3.d_date_sk
        WHERE d3.d_year = 2001
    ) AS avg_store_net_loss
FROM combined c
ORDER BY c.source, c.return_date
LIMIT 100
