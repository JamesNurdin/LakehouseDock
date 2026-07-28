WITH sales_agg AS (
    SELECT
        d_cat.d_year,
        i.i_brand,
        SUM(cs.cs_ext_sales_price)          AS catalog_sales_amount,
        SUM(ss.ss_ext_sales_price)          AS store_sales_amount,
        SUM(ws.ws_ext_sales_price)          AS web_sales_amount,
        SUM(sr.sr_return_amt)               AS store_return_amount,
        SUM(wr.wr_return_amt)               AS web_return_amount,
        COUNT(DISTINCT cs.cs_order_number)  AS distinct_catalog_orders,
        COUNT(DISTINCT ss.ss_ticket_number) AS distinct_store_tickets,
        COUNT(DISTINCT ws.ws_order_number)  AS distinct_web_orders
    FROM
        catalog_sales cs
        JOIN date_dim d_cat ON cs.cs_sold_date_sk = d_cat.d_date_sk
        JOIN item i ON cs.cs_item_sk = i.i_item_sk
        JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
        JOIN store_sales ss
          ON ss.ss_sold_date_sk = d_cat.d_date_sk
         AND ss.ss_item_sk = i.i_item_sk
        JOIN store_returns sr
          ON sr.sr_item_sk = ss.ss_item_sk
         AND sr.sr_returned_date_sk = d_cat.d_date_sk
         AND sr.sr_ticket_number = ss.ss_ticket_number
        JOIN reason r_store ON sr.sr_reason_sk = r_store.r_reason_sk
        JOIN web_sales ws
          ON ws.ws_sold_date_sk = d_cat.d_date_sk
         AND ws.ws_item_sk = i.i_item_sk
        JOIN web_returns wr
          ON wr.wr_item_sk = ws.ws_item_sk
         AND wr.wr_returned_date_sk = d_cat.d_date_sk
         AND wr.wr_order_number = ws.ws_order_number
        JOIN reason r_web ON wr.wr_reason_sk = r_web.r_reason_sk
        JOIN web_site wsite ON ws.ws_web_site_sk = wsite.web_site_sk
        JOIN date_dim d_open ON wsite.web_open_date_sk = d_open.d_date_sk
        JOIN date_dim d_close ON wsite.web_close_date_sk = d_close.d_date_sk
    WHERE
        d_cat.d_year = 2001
        AND i.i_brand = 'Brand#23'
        AND sm.sm_type = 'AIR'
        AND wsite.web_country = 'United States'
    GROUP BY
        GROUPING SETS ((d_cat.d_year, i.i_brand), (d_cat.d_year), ())
)
SELECT
    d_year,
    i_brand,
    SUM(catalog_sales_amount)      AS sum_catalog_sales,
    SUM(store_sales_amount)        AS sum_store_sales,
    SUM(web_sales_amount)          AS sum_web_sales,
    SUM(catalog_sales_amount + store_sales_amount + web_sales_amount) AS total_sales,
    SUM(distinct_catalog_orders)   AS total_distinct_catalog_orders
FROM sales_agg
WHERE (d_year, i_brand) IN (
        SELECT DISTINCT d_year, i_brand
        FROM sales_agg
        WHERE i_brand LIKE 'Brand#%'
    )
GROUP BY
    GROUPING SETS ((d_year, i_brand), (d_year))
HAVING SUM(catalog_sales_amount + store_sales_amount + web_sales_amount) > (
        SELECT AVG(catalog_sales_amount + store_sales_amount + web_sales_amount)
        FROM sales_agg
    )
ORDER BY total_sales DESC
LIMIT 100
