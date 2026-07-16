WITH cs AS (
    SELECT
        d.d_year AS year,
        d.d_month_seq AS month_seq,
        i.i_category AS category,
        i.i_class AS item_class,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        SUM(cs.cs_net_profit) AS total_profit,
        COUNT(DISTINCT cs.cs_order_number) AS order_count,
        SUM(cs.cs_quantity) AS total_quantity
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    GROUP BY d.d_year, d.d_month_seq, i.i_category, i.i_class
),
ss AS (
    SELECT
        d.d_year AS year,
        d.d_month_seq AS month_seq,
        i.i_category AS category,
        i.i_class AS item_class,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        SUM(ss.ss_net_profit) AS total_profit,
        COUNT(DISTINCT ss.ss_ticket_number) AS order_count,
        SUM(ss.ss_quantity) AS total_quantity
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    GROUP BY d.d_year, d.d_month_seq, i.i_category, i.i_class
),
ws AS (
    SELECT
        d.d_year AS year,
        d.d_month_seq AS month_seq,
        i.i_category AS category,
        i.i_class AS item_class,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        SUM(ws.ws_net_profit) AS total_profit,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        SUM(ws.ws_quantity) AS total_quantity
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    GROUP BY d.d_year, d.d_month_seq, i.i_category, i.i_class
),
ret AS (
    SELECT
        d.d_year AS year,
        d.d_month_seq AS month_seq,
        i.i_category AS category,
        i.i_class AS item_class,
        SUM(cr.cr_return_amount) AS total_return,
        SUM(cr.cr_net_loss) AS total_return_loss
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    GROUP BY d.d_year, d.d_month_seq, i.i_category, i.i_class
    UNION ALL
    SELECT
        d.d_year,
        d.d_month_seq,
        i.i_category,
        i.i_class,
        SUM(sr.sr_return_amt) AS total_return,
        SUM(sr.sr_net_loss) AS total_return_loss
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    GROUP BY d.d_year, d.d_month_seq, i.i_category, i.i_class
    UNION ALL
    SELECT
        d.d_year,
        d.d_month_seq,
        i.i_category,
        i.i_class,
        SUM(wr.wr_return_amt) AS total_return,
        SUM(wr.wr_net_loss) AS total_return_loss
    FROM web_returns wr
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN item i ON wr.wr_item_sk = i.i_item_sk
    GROUP BY d.d_year, d.d_month_seq, i.i_category, i.i_class
)

SELECT
    COALESCE(cs.year, ss.year, ws.year, ret.year) AS sales_year,
    COALESCE(cs.month_seq, ss.month_seq, ws.month_seq, ret.month_seq) AS sales_month,
    COALESCE(cs.category, ss.category, ws.category, ret.category) AS item_category,
    COALESCE(cs.item_class, ss.item_class, ws.item_class, ret.item_class) AS item_class,
    COALESCE(cs.total_sales, 0) AS catalog_sales_total,
    COALESCE(ss.total_sales, 0) AS store_sales_total,
    COALESCE(ws.total_sales, 0) AS web_sales_total,
    COALESCE(cs.total_profit, 0) AS catalog_profit_total,
    COALESCE(ss.total_profit, 0) AS store_profit_total,
    COALESCE(ws.total_profit, 0) AS web_profit_total,
    COALESCE(ret.total_return, 0) AS total_returns_amount,
    COALESCE(ret.total_return_loss, 0) AS total_return_loss_amount,
    (COALESCE(cs.total_sales, 0) + COALESCE(ss.total_sales, 0) + COALESCE(ws.total_sales, 0) - COALESCE(ret.total_return, 0)) AS net_sales_amount,
    ROW_NUMBER() OVER (
        PARTITION BY COALESCE(cs.year, ss.year, ws.year, ret.year)
        ORDER BY (COALESCE(cs.total_sales, 0) + COALESCE(ss.total_sales, 0) + COALESCE(ws.total_sales, 0) - COALESCE(ret.total_return, 0)) DESC
    ) AS category_rank
FROM cs
FULL OUTER JOIN ss ON cs.year = ss.year AND cs.month_seq = ss.month_seq AND cs.category = ss.category AND cs.item_class = ss.item_class
FULL OUTER JOIN ws ON COALESCE(cs.year, ss.year) = ws.year AND COALESCE(cs.month_seq, ss.month_seq) = ws.month_seq AND COALESCE(cs.category, ss.category) = ws.category AND COALESCE(cs.item_class, ss.item_class) = ws.item_class
FULL OUTER JOIN ret ON COALESCE(cs.year, ss.year, ws.year) = ret.year AND COALESCE(cs.month_seq, ss.month_seq, ws.month_seq) = ret.month_seq AND COALESCE(cs.category, ss.category, ws.category) = ret.category AND COALESCE(cs.item_class, ss.item_class, ws.item_class) = ret.item_class
ORDER BY sales_year, sales_month, net_sales_amount DESC
LIMIT 100
