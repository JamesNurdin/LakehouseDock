WITH
    store_sales_agg AS (
        SELECT
            d.d_year AS year,
            d.d_month_seq AS month_seq,
            i.i_category AS category,
            'store' AS channel,
            SUM(ss.ss_net_paid) AS total_net_paid,
            SUM(ss.ss_net_profit) AS total_net_profit,
            COUNT(*) AS order_count
        FROM store_sales ss
        JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
        JOIN item i ON ss.ss_item_sk = i.i_item_sk
        GROUP BY d.d_year, d.d_month_seq, i.i_category
    ),
    catalog_sales_agg AS (
        SELECT
            d.d_year AS year,
            d.d_month_seq AS month_seq,
            i.i_category AS category,
            'catalog' AS channel,
            SUM(cs.cs_net_paid) AS total_net_paid,
            SUM(cs.cs_net_profit) AS total_net_profit,
            COUNT(*) AS order_count
        FROM catalog_sales cs
        JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
        JOIN item i ON cs.cs_item_sk = i.i_item_sk
        GROUP BY d.d_year, d.d_month_seq, i.i_category
    ),
    web_sales_agg AS (
        SELECT
            d.d_year AS year,
            d.d_month_seq AS month_seq,
            i.i_category AS category,
            'web' AS channel,
            SUM(ws.ws_net_paid) AS total_net_paid,
            SUM(ws.ws_net_profit) AS total_net_profit,
            COUNT(*) AS order_count
        FROM web_sales ws
        JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
        JOIN item i ON ws.ws_item_sk = i.i_item_sk
        GROUP BY d.d_year, d.d_month_seq, i.i_category
    ),
    returns_agg AS (
        SELECT
            d.d_year AS year,
            d.d_month_seq AS month_seq,
            i.i_category AS category,
            'store' AS channel,
            SUM(sr.sr_net_loss) AS total_net_loss
        FROM store_returns sr
        JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
        JOIN item i ON sr.sr_item_sk = i.i_item_sk
        GROUP BY d.d_year, d.d_month_seq, i.i_category
        UNION ALL
        SELECT
            d.d_year AS year,
            d.d_month_seq AS month_seq,
            i.i_category AS category,
            'catalog' AS channel,
            SUM(cr.cr_net_loss) AS total_net_loss
        FROM catalog_returns cr
        JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
        JOIN item i ON cr.cr_item_sk = i.i_item_sk
        GROUP BY d.d_year, d.d_month_seq, i.i_category
    )
SELECT
    s.year,
    s.month_seq,
    s.category,
    s.channel,
    s.total_net_paid,
    s.total_net_profit,
    COALESCE(r.total_net_loss, 0) AS total_net_loss,
    s.total_net_paid - COALESCE(r.total_net_loss, 0) AS net_paid_after_returns
FROM (
    SELECT * FROM store_sales_agg
    UNION ALL
    SELECT * FROM catalog_sales_agg
    UNION ALL
    SELECT * FROM web_sales_agg
) s
LEFT JOIN returns_agg r
    ON s.year = r.year
    AND s.month_seq = r.month_seq
    AND s.category = r.category
    AND s.channel = r.channel
ORDER BY
    s.year,
    s.month_seq,
    s.category,
    s.channel
