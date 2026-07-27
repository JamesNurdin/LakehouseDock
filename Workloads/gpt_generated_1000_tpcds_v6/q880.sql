/* goal: Compare high‑loss returns by warehouse country and year between catalog and web channels */
WITH catalog_losses AS (
    SELECT
        w.w_country AS country,
        d.d_year    AS year,
        SUM(cr.cr_net_loss) AS total_loss,
        'catalog'   AS source
    FROM tpcds.catalog_returns cr
    JOIN tpcds.date_dim d      ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN tpcds.warehouse w     ON cr.cr_warehouse_sk   = w.w_warehouse_sk
    WHERE d.d_year = 2001
    GROUP BY w.w_country, d.d_year
    HAVING SUM(cr.cr_net_loss) > 1000
),
web_losses AS (
    SELECT
        w.w_country AS country,
        d.d_year    AS year,
        SUM(wr.wr_net_loss) AS total_loss,
        'web'       AS source
    FROM tpcds.web_returns wr
    JOIN tpcds.web_sales ws   ON wr.wr_item_sk = ws.ws_item_sk
                                 AND wr.wr_order_number = ws.ws_order_number
    JOIN tpcds.date_dim d      ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN tpcds.warehouse w     ON ws.ws_warehouse_sk = w.w_warehouse_sk
    WHERE d.d_year = 2001
    GROUP BY w.w_country, d.d_year
    HAVING SUM(wr.wr_net_loss) > 1000
)
SELECT country, year, total_loss, source
FROM catalog_losses
UNION ALL
SELECT country, year, total_loss, source
FROM web_losses
ORDER BY total_loss DESC, country, year
LIMIT 100
