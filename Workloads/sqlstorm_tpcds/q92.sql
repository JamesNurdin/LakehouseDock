WITH
sales_union AS (
    SELECT
        cs.cs_sold_date_sk AS date_sk,
        i.i_category,
        i.i_item_id,
        i.i_item_desc,
        cs.cs_net_profit AS net_profit,
        cs.cs_net_paid_inc_tax AS net_paid,
        'catalog' AS channel
    FROM catalog_sales cs
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    WHERE cs.cs_net_profit IS NOT NULL

    UNION ALL

    SELECT
        ss.ss_sold_date_sk AS date_sk,
        i.i_category,
        i.i_item_id,
        i.i_item_desc,
        ss.ss_net_profit AS net_profit,
        ss.ss_net_paid_inc_tax AS net_paid,
        'store' AS channel
    FROM store_sales ss
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    WHERE ss.ss_net_profit IS NOT NULL

    UNION ALL

    SELECT
        ws.ws_sold_date_sk AS date_sk,
        i.i_category,
        i.i_item_id,
        i.i_item_desc,
        ws.ws_net_profit AS net_profit,
        ws.ws_net_paid_inc_tax AS net_paid,
        'web' AS channel
    FROM web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    WHERE ws.ws_net_profit IS NOT NULL
),
returns_union AS (
    SELECT
        cr.cr_returned_date_sk AS date_sk,
        i.i_category,
        i.i_item_id,
        cr.cr_net_loss AS net_loss,
        cr.cr_return_quantity AS return_qty,
        'catalog' AS channel
    FROM catalog_returns cr
    JOIN item i ON cr.cr_item_sk = i.i_item_sk

    UNION ALL

    SELECT
        sr.sr_returned_date_sk AS date_sk,
        i.i_category,
        i.i_item_id,
        sr.sr_net_loss AS net_loss,
        sr.sr_return_quantity AS return_qty,
        'store' AS channel
    FROM store_returns sr
    JOIN item i ON sr.sr_item_sk = i.i_item_sk

    UNION ALL

    SELECT
        wr.wr_returned_date_sk AS date_sk,
        i.i_category,
        i.i_item_id,
        wr.wr_net_loss AS net_loss,
        wr.wr_return_quantity AS return_qty,
        'web' AS channel
    FROM web_returns wr
    JOIN item i ON wr.wr_item_sk = i.i_item_sk
),
date_info AS (
    SELECT
        d.d_date_sk,
        d.d_year,
        d.d_moy AS month_num,
        d.d_date
    FROM date_dim d
    WHERE d.d_year BETWEEN 1998 AND 2002
),
agg_sales AS (
    SELECT
        su.date_sk,
        di.d_year,
        di.month_num,
        su.i_category,
        su.i_item_id,
        MIN(su.i_item_desc) AS item_desc,
        SUM(su.net_profit) AS total_net_profit,
        SUM(su.net_paid) AS total_net_paid,
        COUNT(*) AS sales_count,
        COUNT(DISTINCT su.channel) AS sales_channels,
        SUM(su.net_profit) / NULLIF(SUM(su.net_paid), 0) AS profit_margin
    FROM sales_union su
    JOIN date_info di ON su.date_sk = di.d_date_sk
    GROUP BY su.date_sk, di.d_year, di.month_num, su.i_category, su.i_item_id
),
agg_returns AS (
    SELECT
        ru.date_sk,
        ru.i_category,
        ru.i_item_id,
        COALESCE(SUM(ru.net_loss), 0) AS total_net_loss,
        COALESCE(SUM(ru.return_qty), 0) AS total_return_qty,
        COUNT(DISTINCT ru.channel) AS return_channels
    FROM returns_union ru
    GROUP BY ru.date_sk, ru.i_category, ru.i_item_id
),
joined AS (
    SELECT
        a.d_year,
        a.month_num,
        a.i_category,
        a.i_item_id,
        COALESCE(a.item_desc, 'UNKNOWN ITEM') AS final_desc,
        a.total_net_profit,
        a.total_net_paid,
        a.profit_margin,
        a.sales_count,
        a.sales_channels,
        COALESCE(r.total_net_loss, 0) AS total_net_loss,
        COALESCE(r.total_return_qty, 0) AS total_return_qty,
        COALESCE(r.return_channels, 0) AS return_channels,
        CASE WHEN COALESCE(r.total_return_qty, 0) > 0 THEN 'YES' ELSE 'NO' END AS had_returns,
        ROW_NUMBER() OVER (PARTITION BY a.d_year, a.i_category ORDER BY a.total_net_profit DESC) AS profit_rank,
        a.total_net_profit - (
            SELECT AVG(total_net_profit)
            FROM agg_sales av
            WHERE av.d_year = a.d_year AND av.i_category = a.i_category
        ) AS profit_vs_avg,
        CASE 
            WHEN a.profit_margin > 0.2 THEN 'HIGH_MARGIN'
            WHEN a.total_net_profit > 10000 THEN 'HIGH_PROFIT'
            ELSE 'NORMAL'
        END AS profit_flag,
        CONCAT(lower(a.i_category), '-', a.i_item_id) AS cat_item_key
    FROM agg_sales a
    LEFT JOIN agg_returns r
        ON a.date_sk = r.date_sk
        AND a.i_category = r.i_category
        AND a.i_item_id = r.i_item_id
),
final_set AS (
    SELECT * FROM joined
    UNION ALL
    SELECT
        t.d_year,
        t.month_num,
        i.i_category,
        i.i_item_id,
        i.final_desc,
        0 AS total_net_profit,
        0 AS total_net_paid,
        NULL AS profit_margin,
        0 AS sales_count,
        0 AS sales_channels,
        0 AS total_net_loss,
        0 AS total_return_qty,
        0 AS return_channels,
        'NO' AS had_returns,
        NULL AS profit_rank,
        NULL AS profit_vs_avg,
        'NO_SALES' AS profit_flag,
        CONCAT(lower(i.i_category), '-', i.i_item_id) AS cat_item_key
    FROM (
        SELECT DISTINCT i_category, i_item_id, i_item_desc AS final_desc FROM item
    ) i
    CROSS JOIN (SELECT 1999 AS d_year, 1 AS month_num) t
    WHERE NOT EXISTS (
        SELECT 1 FROM joined j
        WHERE j.i_category = i.i_category
          AND j.i_item_id = i.i_item_id
    )
)
SELECT
    d_year,
    month_num,
    i_category,
    i_item_id,
    final_desc,
    total_net_profit,
    total_net_paid,
    profit_margin,
    sales_count,
    sales_channels,
    total_net_loss,
    total_return_qty,
    return_channels,
    had_returns,
    profit_rank,
    profit_vs_avg,
    profit_flag,
    cat_item_key
FROM final_set
ORDER BY d_year, month_num, i_category, profit_rank
LIMIT 100
