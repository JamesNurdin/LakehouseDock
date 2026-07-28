WITH item_date_agg AS (
    SELECT
        i.i_item_sk,
        d.d_date_sk,
        d.d_year,
        SUM(cr.cr_net_loss) AS catalog_net_loss,
        SUM(sr.sr_net_loss) AS store_net_loss,
        SUM(cr.cr_return_quantity) AS catalog_return_qty,
        SUM(sr.sr_return_quantity) AS store_return_qty
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN store_returns sr ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
               AND sr.sr_item_sk = i.i_item_sk
    WHERE d.d_year = 2001
      AND i.i_category = 'Women'
      AND cr.cr_return_quantity > 2
    GROUP BY i.i_item_sk, d.d_date_sk, d.d_year
)
SELECT
    iad.i_item_sk,
    iad.d_date_sk,
    iad.d_year,
    iad.catalog_net_loss,
    iad.store_net_loss,
    (iad.catalog_net_loss + iad.store_net_loss) AS total_net_loss,
    RANK() OVER (ORDER BY (iad.catalog_net_loss + iad.store_net_loss) DESC) AS loss_rank,
    (
        SELECT AVG(cr2.cr_net_loss)
        FROM catalog_returns cr2
        JOIN date_dim d2 ON cr2.cr_returned_date_sk = d2.d_date_sk
        JOIN item i2 ON cr2.cr_item_sk = i2.i_item_sk
        WHERE i2.i_category = 'Women'
          AND d2.d_year = iad.d_year
    ) AS avg_category_loss_year
FROM item_date_agg iad
WHERE (iad.catalog_net_loss + iad.store_net_loss) > 0
ORDER BY total_net_loss DESC
LIMIT 100
