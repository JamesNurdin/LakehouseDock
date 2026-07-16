WITH catalog_returns_agg AS (
    SELECT cr_item_sk, cr_order_number, SUM(cr_return_amount) AS return_amount
    FROM catalog_returns
    GROUP BY cr_item_sk, cr_order_number
), web_returns_agg AS (
    SELECT wr_item_sk, wr_order_number, SUM(wr_return_amt) AS return_amount
    FROM web_returns
    GROUP BY wr_item_sk, wr_order_number
), store_returns_agg AS (
    SELECT sr_item_sk, sr_ticket_number, SUM(sr_return_amt) AS return_amount
    FROM store_returns
    GROUP BY sr_item_sk, sr_ticket_number
), catalog AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        i.i_category,
        SUM(cs.cs_net_paid - COALESCE(cr.return_amount, 0)) AS net_revenue,
        SUM(cs.cs_ext_sales_price) AS gross_sales,
        COUNT(DISTINCT cs.cs_order_number) AS orders
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    LEFT JOIN catalog_returns_agg cr
        ON cs.cs_item_sk = cr.cr_item_sk
        AND cs.cs_order_number = cr.cr_order_number
    WHERE d.d_year = 2000
    GROUP BY d.d_year, d.d_month_seq, i.i_category
), web AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        i.i_category,
        SUM(ws.ws_net_paid - COALESCE(wr.return_amount, 0)) AS net_revenue,
        SUM(ws.ws_ext_sales_price) AS gross_sales,
        COUNT(DISTINCT ws.ws_order_number) AS orders
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    LEFT JOIN web_returns_agg wr
        ON ws.ws_item_sk = wr.wr_item_sk
        AND ws.ws_order_number = wr.wr_order_number
    WHERE d.d_year = 2000
    GROUP BY d.d_year, d.d_month_seq, i.i_category
), store AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        i.i_category,
        SUM(ss.ss_net_paid - COALESCE(sr.return_amount, 0)) AS net_revenue,
        SUM(ss.ss_ext_sales_price) AS gross_sales,
        COUNT(DISTINCT ss.ss_ticket_number) AS orders
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    LEFT JOIN store_returns_agg sr
        ON ss.ss_item_sk = sr.sr_item_sk
        AND ss.ss_ticket_number = sr.sr_ticket_number
    WHERE d.d_year = 2000
    GROUP BY d.d_year, d.d_month_seq, i.i_category
)
SELECT d_year, d_month_seq, 'Catalog' AS channel, i_category, net_revenue, gross_sales, orders
FROM catalog
UNION ALL
SELECT d_year, d_month_seq, 'Web' AS channel, i_category, net_revenue, gross_sales, orders
FROM web
UNION ALL
SELECT d_year, d_month_seq, 'Store' AS channel, i_category, net_revenue, gross_sales, orders
FROM store
ORDER BY d_year, d_month_seq, channel, i_category
