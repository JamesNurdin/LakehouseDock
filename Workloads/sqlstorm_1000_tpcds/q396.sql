WITH sales_agg AS (
    SELECT
        d.d_year AS year,
        d.d_moy AS month,
        i.i_category AS category,
        SUM(ss.ss_net_paid_inc_tax) AS total_sales,
        SUM(ss.ss_net_profit) AS total_profit,
        SUM(ss.ss_quantity) AS total_quantity,
        'store' AS channel
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    GROUP BY d.d_year, d.d_moy, i.i_category

    UNION ALL

    SELECT
        d.d_year,
        d.d_moy,
        i.i_category,
        SUM(cs.cs_net_paid_inc_tax),
        SUM(cs.cs_net_profit),
        SUM(cs.cs_quantity),
        'catalog'
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    GROUP BY d.d_year, d.d_moy, i.i_category

    UNION ALL

    SELECT
        d.d_year,
        d.d_moy,
        i.i_category,
        SUM(ws.ws_net_paid_inc_tax),
        SUM(ws.ws_net_profit),
        SUM(ws.ws_quantity),
        'web'
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    GROUP BY d.d_year, d.d_moy, i.i_category
),
returns_agg AS (
    SELECT
        d.d_year AS year,
        d.d_moy AS month,
        i.i_category AS category,
        SUM(sr.sr_net_loss) AS total_return_loss,
        SUM(sr.sr_return_quantity) AS total_return_qty,
        'store' AS channel
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    GROUP BY d.d_year, d.d_moy, i.i_category

    UNION ALL

    SELECT
        d.d_year,
        d.d_moy,
        i.i_category,
        SUM(cr.cr_net_loss),
        SUM(cr.cr_return_quantity),
        'catalog'
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    GROUP BY d.d_year, d.d_moy, i.i_category

    UNION ALL

    SELECT
        d.d_year,
        d.d_moy,
        i.i_category,
        SUM(wr.wr_net_loss),
        SUM(wr.wr_return_quantity),
        'web'
    FROM web_returns wr
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN item i ON wr.wr_item_sk = i.i_item_sk
    GROUP BY d.d_year, d.d_moy, i.i_category
)
SELECT
    s.year,
    s.month,
    s.category,
    s.channel,
    s.total_sales,
    s.total_profit,
    s.total_quantity,
    COALESCE(r.total_return_loss, 0) AS total_return_loss,
    COALESCE(r.total_return_qty, 0) AS total_return_qty,
    CASE
        WHEN s.total_quantity > 0 THEN CAST(COALESCE(r.total_return_qty, 0) AS double) / CAST(s.total_quantity AS double)
        ELSE 0
    END AS return_rate,
    RANK() OVER (PARTITION BY s.year, s.month ORDER BY s.total_profit DESC) AS profit_rank
FROM sales_agg s
LEFT JOIN returns_agg r
    ON s.year = r.year
   AND s.month = r.month
   AND s.category = r.category
   AND s.channel = r.channel
ORDER BY s.year, s.month, profit_rank
