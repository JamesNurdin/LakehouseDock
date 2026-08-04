WITH avg_loss AS (
    SELECT avg(cr_net_loss) AS avg_net_loss
    FROM catalog_returns
),
store_loss AS (
    SELECT
        'Store' AS source_type,
        s.s_store_name AS location_name,
        d.d_date AS return_date,
        SUM(sr.sr_net_loss) AS total_net_loss
    FROM store_returns sr
    INNER JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    INNER JOIN store s ON sr.sr_store_sk = s.s_store_sk
    WHERE d.d_year = 2001
      AND sr.sr_net_loss > (SELECT avg_net_loss FROM avg_loss)
    GROUP BY s.s_store_name, d.d_date
),
warehouse_loss AS (
    SELECT
        'Warehouse' AS source_type,
        w.w_warehouse_name AS location_name,
        d.d_date AS return_date,
        SUM(cr.cr_net_loss) AS total_net_loss
    FROM catalog_returns cr
    INNER JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    INNER JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
    WHERE d.d_year = 2001
      AND cr.cr_net_loss > (SELECT avg_net_loss FROM avg_loss)
    GROUP BY w.w_warehouse_name, d.d_date
)
SELECT source_type, location_name, return_date, total_net_loss
FROM (
    SELECT * FROM store_loss
    UNION ALL
    SELECT * FROM warehouse_loss
) AS combined
ORDER BY total_net_loss DESC
LIMIT 100
