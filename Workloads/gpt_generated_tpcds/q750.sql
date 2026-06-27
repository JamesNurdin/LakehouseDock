WITH
    sales_data AS (
        SELECT
            date_trunc('month', d_sold.d_date) AS month_date,
            i.i_category,
            ss.ss_quantity                AS quantity_sold,
            ss.ss_net_profit              AS net_profit
        FROM store_sales ss
        JOIN date_dim d_sold ON ss.ss_sold_date_sk = d_sold.d_date_sk
        JOIN item i ON ss.ss_item_sk = i.i_item_sk
        WHERE d_sold.d_date BETWEEN DATE '2001-01-01' AND DATE '2001-12-31'
        UNION ALL
        SELECT
            date_trunc('month', d_sold.d_date) AS month_date,
            i.i_category,
            cs.cs_quantity                AS quantity_sold,
            cs.cs_net_profit              AS net_profit
        FROM catalog_sales cs
        JOIN date_dim d_sold ON cs.cs_sold_date_sk = d_sold.d_date_sk
        JOIN item i ON cs.cs_item_sk = i.i_item_sk
        WHERE d_sold.d_date BETWEEN DATE '2001-01-01' AND DATE '2001-12-31'
        UNION ALL
        SELECT
            date_trunc('month', d_sold.d_date) AS month_date,
            i.i_category,
            ws.ws_quantity                AS quantity_sold,
            ws.ws_net_profit              AS net_profit
        FROM web_sales ws
        JOIN date_dim d_sold ON ws.ws_sold_date_sk = d_sold.d_date_sk
        JOIN item i ON ws.ws_item_sk = i.i_item_sk
        WHERE d_sold.d_date BETWEEN DATE '2001-01-01' AND DATE '2001-12-31'
    ),
    returns_data AS (
        SELECT
            date_trunc('month', d_ret.d_date) AS month_date,
            i.i_category,
            sr.sr_return_quantity         AS quantity_returned,
            sr.sr_net_loss                AS net_loss
        FROM store_returns sr
        JOIN date_dim d_ret ON sr.sr_returned_date_sk = d_ret.d_date_sk
        JOIN item i ON sr.sr_item_sk = i.i_item_sk
        WHERE d_ret.d_date BETWEEN DATE '2001-01-01' AND DATE '2001-12-31'
        UNION ALL
        SELECT
            date_trunc('month', d_ret.d_date) AS month_date,
            i.i_category,
            cr.cr_return_quantity         AS quantity_returned,
            cr.cr_net_loss                AS net_loss
        FROM catalog_returns cr
        JOIN date_dim d_ret ON cr.cr_returned_date_sk = d_ret.d_date_sk
        JOIN item i ON cr.cr_item_sk = i.i_item_sk
        WHERE d_ret.d_date BETWEEN DATE '2001-01-01' AND DATE '2001-12-31'
        UNION ALL
        SELECT
            date_trunc('month', d_ret.d_date) AS month_date,
            i.i_category,
            wr.wr_return_quantity         AS quantity_returned,
            wr.wr_net_loss                AS net_loss
        FROM web_returns wr
        JOIN date_dim d_ret ON wr.wr_returned_date_sk = d_ret.d_date_sk
        JOIN item i ON wr.wr_item_sk = i.i_item_sk
        WHERE d_ret.d_date BETWEEN DATE '2001-01-01' AND DATE '2001-12-31'
    )
SELECT
    s.month_date,
    s.i_category,
    SUM(s.quantity_sold)                         AS total_quantity_sold,
    SUM(s.net_profit)                            AS total_net_profit,
    COALESCE(SUM(r.quantity_returned), 0)        AS total_quantity_returned,
    COALESCE(SUM(r.net_loss), 0)                 AS total_net_loss,
    SUM(s.net_profit) - COALESCE(SUM(r.net_loss), 0) AS net_contribution,
    CASE
        WHEN SUM(s.quantity_sold) = 0 THEN 0
        ELSE COALESCE(SUM(r.quantity_returned), 0) * 1.0 / SUM(s.quantity_sold)
    END                                          AS return_rate
FROM sales_data s
LEFT JOIN returns_data r
    ON s.month_date = r.month_date
   AND s.i_category = r.i_category
GROUP BY
    s.month_date,
    s.i_category
ORDER BY
    s.month_date,
    s.i_category
