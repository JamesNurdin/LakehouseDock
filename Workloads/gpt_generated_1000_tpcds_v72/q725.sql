/* goal: Compare daily sales performance of the catalog channel versus the web channel for the year 2001, ranking days by sales amount and showing inventory availability per warehouse. */
WITH date_filtered AS (
    SELECT d_date_sk,
           d_year,
           d_month_seq
    FROM   tpcds.date_dim
    WHERE  d_year = 2001
)
SELECT *
FROM (
    /* Catalog sales side */
    SELECT
        cs.cs_sold_date_sk                         AS date_sk,
        d.d_year,
        'Catalog'                                   AS channel,
        SUM(cs.cs_ext_sales_price)                 AS total_sales,
        SUM(cs.cs_net_profit)                      AS total_profit,
        ROW_NUMBER() OVER (PARTITION BY cs.cs_sold_date_sk ORDER BY SUM(cs.cs_ext_sales_price) DESC) AS sales_rank,
        (
            SELECT AVG(cs2.cs_ext_sales_price)
            FROM   tpcds.catalog_sales cs2
            WHERE  cs2.cs_sold_date_sk = cs.cs_sold_date_sk
        )                                           AS avg_daily_sales,
        inv_sum.total_on_hand
    FROM   tpcds.catalog_sales cs
    JOIN   date_filtered d
           ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN   tpcds.catalog_page cp
           ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN   tpcds.warehouse w
           ON cs.cs_warehouse_sk = w.w_warehouse_sk
    CROSS JOIN LATERAL (
        SELECT SUM(i.inv_quantity_on_hand) AS total_on_hand
        FROM   tpcds.inventory i
        WHERE  i.inv_warehouse_sk = w.w_warehouse_sk
    ) inv_sum
    WHERE  cp.cp_department = 'Books'
    GROUP BY cs.cs_sold_date_sk, d.d_year, inv_sum.total_on_hand
    HAVING SUM(cs.cs_ext_sales_price) > (
        SELECT AVG(cs3.cs_ext_sales_price)
        FROM   tpcds.catalog_sales cs3
        WHERE  cs3.cs_sold_date_sk = cs.cs_sold_date_sk
    )

    UNION ALL

    /* Web sales side */
    SELECT
        ws.ws_sold_date_sk                         AS date_sk,
        d.d_year,
        'Web'                                      AS channel,
        SUM(ws.ws_ext_sales_price)                 AS total_sales,
        SUM(ws.ws_net_profit)                      AS total_profit,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_sold_date_sk ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS sales_rank,
        (
            SELECT AVG(ws2.ws_ext_sales_price)
            FROM   tpcds.web_sales ws2
            WHERE  ws2.ws_sold_date_sk = ws.ws_sold_date_sk
        )                                           AS avg_daily_sales,
        inv_sum.total_on_hand
    FROM   tpcds.web_sales ws
    JOIN   date_filtered d
           ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN   tpcds.web_page wp
           ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN   tpcds.warehouse w
           ON ws.ws_warehouse_sk = w.w_warehouse_sk
    CROSS JOIN LATERAL (
        SELECT SUM(i.inv_quantity_on_hand) AS total_on_hand
        FROM   tpcds.inventory i
        WHERE  i.inv_warehouse_sk = w.w_warehouse_sk
    ) inv_sum
    WHERE  wp.wp_type = 'HomePage'
    GROUP BY ws.ws_sold_date_sk, d.d_year, inv_sum.total_on_hand
    HAVING SUM(ws.ws_ext_sales_price) > (
        SELECT AVG(ws3.ws_ext_sales_price)
        FROM   tpcds.web_sales ws3
        WHERE  ws3.ws_sold_date_sk = ws.ws_sold_date_sk
    )
) combined_results
ORDER BY date_sk,
         channel,
         total_sales DESC
LIMIT 100
