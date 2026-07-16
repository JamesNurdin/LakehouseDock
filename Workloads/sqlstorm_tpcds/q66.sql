SELECT
    d_year,
    i_category,
    i_brand,
    i_color,
    total_net_profit,
    total_net_paid,
    total_return_loss,
    CASE WHEN total_net_paid = 0 THEN NULL ELSE total_net_profit / total_net_paid END AS profit_margin,
    RANK() OVER (PARTITION BY d_year ORDER BY total_net_profit DESC) AS profit_rank
FROM (
    SELECT
        d.d_year,
        i.i_category,
        i.i_brand,
        i.i_color,
        SUM(t.net_profit) AS total_net_profit,
        SUM(t.net_paid) AS total_net_paid,
        SUM(t.net_loss) AS total_return_loss
    FROM (
        SELECT
            ss_sold_date_sk AS date_sk,
            ss_item_sk AS item_sk,
            ss_net_profit AS net_profit,
            ss_net_paid_inc_tax AS net_paid,
            CAST(0.00 AS decimal(7,2)) AS net_loss
        FROM store_sales
        UNION ALL
        SELECT
            cs_sold_date_sk,
            cs_item_sk,
            cs_net_profit,
            cs_net_paid_inc_ship_tax,
            CAST(0.00 AS decimal(7,2))
        FROM catalog_sales
        UNION ALL
        SELECT
            ws_sold_date_sk,
            ws_item_sk,
            ws_net_profit,
            ws_net_paid_inc_ship_tax,
            CAST(0.00 AS decimal(7,2))
        FROM web_sales
        UNION ALL
        SELECT
            sr_returned_date_sk,
            sr_item_sk,
            -sr_net_loss,
            -sr_net_loss,
            sr_net_loss
        FROM store_returns
        UNION ALL
        SELECT
            cr_returned_date_sk,
            cr_item_sk,
            -cr_net_loss,
            -cr_net_loss,
            cr_net_loss
        FROM catalog_returns
        UNION ALL
        SELECT
            wr_returned_date_sk,
            wr_item_sk,
            -wr_net_loss,
            -wr_net_loss,
            wr_net_loss
        FROM web_returns
    ) t
    JOIN date_dim d ON t.date_sk = d.d_date_sk
    JOIN item i ON t.item_sk = i.i_item_sk
    GROUP BY GROUPING SETS (
        (d.d_year, i.i_category, i.i_brand, i.i_color),
        (d.d_year, i.i_category, i.i_brand),
        (d.d_year, i.i_category),
        (d.d_year)
    )
    HAVING SUM(t.net_profit) > 0
) agg
ORDER BY d_year, total_net_profit DESC
