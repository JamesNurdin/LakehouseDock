WITH
    store_sales_monthly AS (
        SELECT
            d.d_year AS year,
            d.d_moy AS month,
            SUM(ss.ss_net_profit) AS store_net_profit
        FROM store_sales ss
        JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
        GROUP BY d.d_year, d.d_moy
    ),
    store_returns_monthly AS (
        SELECT
            d.d_year AS year,
            d.d_moy AS month,
            SUM(sr.sr_net_loss) AS store_net_loss
        FROM store_returns sr
        JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
        GROUP BY d.d_year, d.d_moy
    ),
    catalog_sales_monthly AS (
        SELECT
            d.d_year AS year,
            d.d_moy AS month,
            SUM(cs.cs_net_profit) AS catalog_net_profit
        FROM catalog_sales cs
        JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
        GROUP BY d.d_year, d.d_moy
    ),
    catalog_returns_monthly AS (
        SELECT
            d.d_year AS year,
            d.d_moy AS month,
            SUM(cr.cr_net_loss) AS catalog_net_loss
        FROM catalog_returns cr
        JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
        GROUP BY d.d_year, d.d_moy
    ),
    web_sales_monthly AS (
        SELECT
            d.d_year AS year,
            d.d_moy AS month,
            SUM(ws.ws_net_profit) AS web_net_profit
        FROM web_sales ws
        JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
        GROUP BY d.d_year, d.d_moy
    ),
    all_months AS (
        SELECT year, month FROM store_sales_monthly
        UNION
        SELECT year, month FROM store_returns_monthly
        UNION
        SELECT year, month FROM catalog_sales_monthly
        UNION
        SELECT year, month FROM catalog_returns_monthly
        UNION
        SELECT year, month FROM web_sales_monthly
    )
SELECT
    am.year,
    am.month,
    COALESCE(ssm.store_net_profit, 0) +
    COALESCE(csm.catalog_net_profit, 0) +
    COALESCE(wsm.web_net_profit, 0) -
    COALESCE(srm.store_net_loss, 0) -
    COALESCE(crm.catalog_net_loss, 0) AS total_net_profit,
    COALESCE(ssm.store_net_profit, 0) AS store_net_profit,
    COALESCE(csm.catalog_net_profit, 0) AS catalog_net_profit,
    COALESCE(wsm.web_net_profit, 0) AS web_net_profit,
    COALESCE(srm.store_net_loss, 0) AS store_net_loss,
    COALESCE(crm.catalog_net_loss, 0) AS catalog_net_loss
FROM all_months am
LEFT JOIN store_sales_monthly ssm ON am.year = ssm.year AND am.month = ssm.month
LEFT JOIN store_returns_monthly srm ON am.year = srm.year AND am.month = srm.month
LEFT JOIN catalog_sales_monthly csm ON am.year = csm.year AND am.month = csm.month
LEFT JOIN catalog_returns_monthly crm ON am.year = crm.year AND am.month = crm.month
LEFT JOIN web_sales_monthly wsm ON am.year = wsm.year AND am.month = wsm.month
ORDER BY am.year, am.month
