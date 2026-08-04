WITH catalog_stats AS (
    SELECT
        d.d_year,
        SUM(cr.cr_net_loss) AS net_loss,
        SUM(inv.inv_quantity_on_hand) AS inventory_qty,
        'catalog' AS source
    FROM catalog_returns cr
    FULL OUTER JOIN date_dim d
        ON cr.cr_returned_date_sk = d.d_date_sk
    FULL OUTER JOIN (
        SELECT * FROM inventory TABLESAMPLE BERNOULLI (20)
    ) inv
        ON inv.inv_date_sk = d.d_date_sk
    WHERE d.d_year BETWEEN 2000 AND 2002
    GROUP BY d.d_year
),
web_stats AS (
    SELECT
        d.d_year,
        SUM(wr.wr_net_loss) AS net_loss,
        SUM(inv.inv_quantity_on_hand) AS inventory_qty,
        'web' AS source
    FROM web_returns wr
    FULL OUTER JOIN date_dim d
        ON wr.wr_returned_date_sk = d.d_date_sk
    FULL OUTER JOIN (
        SELECT * FROM inventory TABLESAMPLE BERNOULLI (20)
    ) inv
        ON inv.inv_date_sk = d.d_date_sk
    WHERE d.d_year BETWEEN 2000 AND 2002
    GROUP BY d.d_year
)
SELECT d_year, net_loss, inventory_qty, source
FROM catalog_stats
UNION
SELECT d_year, net_loss, inventory_qty, source
FROM web_stats
ORDER BY d_year, source
