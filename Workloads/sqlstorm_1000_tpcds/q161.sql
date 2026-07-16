WITH all_sales AS (
    SELECT d.d_year AS year,
           s.s_country AS country,
           i.i_category AS category,
           ss.ss_net_profit AS profit,
           CAST(0 AS decimal(7,2)) AS loss,
           ss.ss_quantity AS quantity
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    UNION ALL
    SELECT d.d_year,
           cc.cc_country,
           i.i_category,
           cs.cs_net_profit,
           CAST(0 AS decimal(7,2)),
           cs.cs_quantity
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    UNION ALL
    SELECT d.d_year,
           w.web_country,
           i.i_category,
           ws.ws_net_profit,
           CAST(0 AS decimal(7,2)),
           ws.ws_quantity
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN web_site w ON ws.ws_web_site_sk = w.web_site_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    UNION ALL
    SELECT d.d_year,
           s.s_country,
           i.i_category,
           CAST(0 AS decimal(7,2)),
           sr.sr_net_loss,
           0
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    UNION ALL
    SELECT d.d_year,
           cc.cc_country,
           i.i_category,
           CAST(0 AS decimal(7,2)),
           cr.cr_net_loss,
           0
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    UNION ALL
    SELECT d.d_year,
           CAST('UNKNOWN' AS varchar),
           i.i_category,
           CAST(0 AS decimal(7,2)),
           wr.wr_net_loss,
           0
    FROM web_returns wr
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN item i ON wr.wr_item_sk = i.i_item_sk
),
agg AS (
    SELECT
        year,
        country,
        category,
        SUM(profit) AS total_profit,
        SUM(loss) AS total_loss,
        SUM(quantity) AS total_quantity
    FROM all_sales
    GROUP BY year, country, category
),
ranked AS (
    SELECT
        year,
        country,
        category,
        total_profit,
        total_loss,
        total_quantity,
        CASE WHEN total_loss = 0 THEN NULL ELSE total_profit / total_loss END AS profit_loss_ratio,
        CASE WHEN total_quantity = 0 THEN NULL ELSE total_profit / total_quantity END AS profit_per_unit,
        RANK() OVER (PARTITION BY year, country ORDER BY total_profit DESC) AS profit_rank,
        AVG(total_profit) OVER (PARTITION BY country, category ORDER BY year ROWS BETWEEN 2 PRECEDING AND CURRENT ROW) AS profit_3yr_moving_avg,
        AVG(CASE WHEN total_quantity = 0 THEN NULL ELSE total_profit / total_quantity END) OVER (PARTITION BY country, category ORDER BY year ROWS BETWEEN 2 PRECEDING AND CURRENT ROW) AS profit_per_unit_3yr_moving_avg
    FROM agg
)
SELECT
    year,
    country,
    category,
    total_profit,
    total_loss,
    total_quantity,
    profit_loss_ratio,
    profit_per_unit,
    profit_rank,
    profit_3yr_moving_avg,
    profit_per_unit_3yr_moving_avg
FROM ranked
WHERE profit_rank <= 5
ORDER BY year, country, profit_rank
