WITH
    store_sales_agg AS (
        SELECT
            d.d_year AS year,
            i.i_category AS category,
            SUM(ss.ss_net_paid)   AS store_net_paid,
            SUM(ss.ss_net_profit) AS store_net_profit
        FROM store_sales ss
        JOIN date_dim d   ON ss.ss_sold_date_sk = d.d_date_sk
        JOIN item i       ON ss.ss_item_sk      = i.i_item_sk
        GROUP BY d.d_year, i.i_category
    ),
    catalog_sales_agg AS (
        SELECT
            d.d_year AS year,
            i.i_category AS category,
            SUM(cs.cs_net_paid)   AS catalog_net_paid,
            SUM(cs.cs_net_profit) AS catalog_net_profit
        FROM catalog_sales cs
        JOIN date_dim d   ON cs.cs_sold_date_sk = d.d_date_sk
        JOIN item i       ON cs.cs_item_sk      = i.i_item_sk
        GROUP BY d.d_year, i.i_category
    ),
    catalog_returns_agg AS (
        SELECT
            d.d_year AS year,
            i.i_category AS category,
            SUM(cr.cr_net_loss) AS catalog_net_loss
        FROM catalog_returns cr
        JOIN date_dim d   ON cr.cr_returned_date_sk = d.d_date_sk
        JOIN item i       ON cr.cr_item_sk          = i.i_item_sk
        GROUP BY d.d_year, i.i_category
    ),
    web_returns_agg AS (
        SELECT
            d.d_year AS year,
            i.i_category AS category,
            SUM(wr.wr_net_loss) AS web_net_loss
        FROM web_returns wr
        JOIN date_dim d   ON wr.wr_returned_date_sk = d.d_date_sk
        JOIN item i       ON wr.wr_item_sk          = i.i_item_sk
        GROUP BY d.d_year, i.i_category
    )
SELECT
    COALESCE(ss.year, cs.year, cr.year, wr.year)       AS year,
    COALESCE(ss.category, cs.category, cr.category, wr.category) AS category,
    ss.store_net_paid,
    ss.store_net_profit,
    cs.catalog_net_paid,
    cs.catalog_net_profit,
    cr.catalog_net_loss,
    wr.web_net_loss,
    (COALESCE(ss.store_net_profit, 0) + COALESCE(cs.catalog_net_profit, 0)
     - COALESCE(cr.catalog_net_loss, 0) - COALESCE(wr.web_net_loss, 0)) AS total_net_profit
FROM store_sales_agg   ss
FULL OUTER JOIN catalog_sales_agg   cs ON ss.year = cs.year AND ss.category = cs.category
FULL OUTER JOIN catalog_returns_agg cr ON COALESCE(ss.year, cs.year) = cr.year
                                         AND COALESCE(ss.category, cs.category) = cr.category
FULL OUTER JOIN web_returns_agg    wr ON COALESCE(ss.year, cs.year, cr.year) = wr.year
                                         AND COALESCE(ss.category, cs.category, cr.category) = wr.category
ORDER BY year, category
