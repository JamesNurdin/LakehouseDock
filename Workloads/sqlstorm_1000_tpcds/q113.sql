WITH store AS (
    SELECT
        'store' AS channel,
        d.d_year AS sales_year,
        d.d_moy AS month,
        SUM(ss.ss_ext_sales_price) AS sales,
        SUM(COALESCE(sr.sr_return_amt_inc_tax, 0)) AS returns
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    LEFT JOIN store_returns sr
        ON ss.ss_ticket_number = sr.sr_ticket_number
        AND ss.ss_store_sk = sr.sr_store_sk
        AND ss.ss_item_sk = sr.sr_item_sk
    GROUP BY d.d_year, d.d_moy
), catalog AS (
    SELECT
        'catalog' AS channel,
        d.d_year AS sales_year,
        d.d_moy AS month,
        SUM(cs.cs_ext_sales_price) AS sales,
        SUM(COALESCE(cr.cr_return_amt_inc_tax, 0)) AS returns
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    LEFT JOIN catalog_returns cr
        ON cs.cs_order_number = cr.cr_order_number
        AND cs.cs_item_sk = cr.cr_item_sk
    GROUP BY d.d_year, d.d_moy
), web AS (
    SELECT
        'web' AS channel,
        d.d_year AS sales_year,
        d.d_moy AS month,
        SUM(ws.ws_ext_sales_price) AS sales,
        SUM(COALESCE(wr.wr_return_amt_inc_tax, 0)) AS returns
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    LEFT JOIN web_returns wr
        ON ws.ws_order_number = wr.wr_order_number
        AND ws.ws_item_sk = wr.wr_item_sk
    GROUP BY d.d_year, d.d_moy
)
SELECT
    channel,
    sales_year,
    month,
    sales,
    returns,
    sales - returns AS net_revenue
FROM (
    SELECT * FROM store
    UNION ALL
    SELECT * FROM catalog
    UNION ALL
    SELECT * FROM web
) t
ORDER BY channel, sales_year, month
