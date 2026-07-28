WITH catalog_agg AS (
    SELECT
        'Catalog' AS return_source,
        d.d_year AS year,
        SUM(cr.cr_net_loss) AS total_net_loss
    FROM tpcds.catalog_returns cr
    JOIN tpcds.date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN tpcds.item i ON cr.cr_item_sk = i.i_item_sk
    JOIN tpcds.warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
    WHERE d.d_year BETWEEN 1998 AND 2002
      AND i.i_current_price > (
            SELECT AVG(i2.i_current_price)
            FROM tpcds.item i2
        )
    GROUP BY d.d_year
),
web_agg AS (
    SELECT
        'Web' AS return_source,
        d.d_year AS year,
        SUM(wr.wr_net_loss) AS total_net_loss
    FROM tpcds.web_returns wr
    JOIN tpcds.date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN tpcds.item i ON wr.wr_item_sk = i.i_item_sk
    JOIN tpcds.web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
    WHERE d.d_year BETWEEN 1998 AND 2002
      AND EXISTS (
            SELECT 1
            FROM tpcds.web_page wp2
            WHERE wp2.wp_web_page_sk = wp.wp_web_page_sk
              AND wp2.wp_link_count > 10
        )
    GROUP BY d.d_year
)
SELECT return_source, year, total_net_loss
FROM catalog_agg
UNION ALL
SELECT return_source, year, total_net_loss
FROM web_agg
ORDER BY year, total_net_loss DESC
LIMIT 100
