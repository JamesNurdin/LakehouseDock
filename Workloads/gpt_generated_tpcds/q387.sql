WITH combined AS (
    SELECT
        dd.d_year,
        dd.d_moy,
        i.i_item_id,
        i.i_product_name,
        ss.ss_net_profit AS profit
    FROM store_sales ss
    JOIN date_dim dd ON ss.ss_sold_date_sk = dd.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk

    UNION ALL

    SELECT
        dd.d_year,
        dd.d_moy,
        i.i_item_id,
        i.i_product_name,
        cs.cs_net_profit AS profit
    FROM catalog_sales cs
    JOIN date_dim dd ON cs.cs_sold_date_sk = dd.d_date_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk

    UNION ALL

    SELECT
        dd.d_year,
        dd.d_moy,
        i.i_item_id,
        i.i_product_name,
        ws.ws_net_profit AS profit
    FROM web_sales ws
    JOIN date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk

    UNION ALL

    SELECT
        dd.d_year,
        dd.d_moy,
        i.i_item_id,
        i.i_product_name,
        -cr.cr_net_loss AS profit
    FROM catalog_returns cr
    JOIN date_dim dd ON cr.cr_returned_date_sk = dd.d_date_sk
    JOIN item i ON cr.cr_item_sk = i.i_item_sk

    UNION ALL

    SELECT
        dd.d_year,
        dd.d_moy,
        i.i_item_id,
        i.i_product_name,
        -sr.sr_net_loss AS profit
    FROM store_returns sr
    JOIN date_dim dd ON sr.sr_returned_date_sk = dd.d_date_sk
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
)
SELECT
    combined.d_year,
    combined.d_moy,
    combined.i_item_id,
    combined.i_product_name,
    SUM(combined.profit) AS total_net_profit
FROM combined
WHERE combined.d_year = 2001
GROUP BY combined.d_year, combined.d_moy, combined.i_item_id, combined.i_product_name
HAVING SUM(combined.profit) > 0
ORDER BY total_net_profit DESC
LIMIT 20
