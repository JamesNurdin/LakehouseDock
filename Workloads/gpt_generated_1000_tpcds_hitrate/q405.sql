WITH sales AS (
    SELECT
        i.i_category AS i_category,
        t.t_hour AS t_hour,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        SUM(ss.ss_net_profit) AS total_profit,
        CASE WHEN SUM(ss.ss_net_profit) > 0 THEN 'POS' ELSE 'NEG' END AS profit_flag,
        (SELECT AVG(ss2.ss_net_profit) FROM store_sales ss2) AS avg_profit_overall
    FROM store_sales ss
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
    GROUP BY GROUPING SETS (
        (i.i_category, t.t_hour),
        (i.i_category)
    )
),
returns AS (
    SELECT
        i.i_category AS i_category,
        t.t_hour AS t_hour,
        -SUM(cr.cr_return_amount) AS total_sales,
        SUM(cr.cr_net_loss) AS total_profit,
        CASE WHEN SUM(cr.cr_net_loss) > 0 THEN 'LOSS' ELSE 'GAIN' END AS profit_flag,
        (SELECT AVG(cr2.cr_net_loss) FROM catalog_returns cr2) AS avg_profit_overall
    FROM catalog_returns cr
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    JOIN time_dim t ON cr.cr_returned_time_sk = t.t_time_sk
    GROUP BY GROUPING SETS (
        (i.i_category, t.t_hour),
        (i.i_category)
    )
)
SELECT *
FROM sales
UNION ALL
SELECT *
FROM returns
ORDER BY i_category, t_hour NULLS LAST, total_sales DESC
LIMIT 100
