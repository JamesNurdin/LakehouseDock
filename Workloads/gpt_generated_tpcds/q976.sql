WITH catalog_sales_agg AS (
    SELECT
        cd.d_year,
        cd.d_month_seq,
        cc.cc_division_name AS division_name,
        cp.cp_type AS page_type,
        SUM(cs.cs_net_paid) AS total_net_paid,
        SUM(cs.cs_net_profit) AS total_net_profit,
        SUM(COALESCE(cr.cr_net_loss, 0)) AS total_return_loss
    FROM catalog_sales cs
    JOIN date_dim cd
        ON cs.cs_sold_date_sk = cd.d_date_sk
    JOIN call_center cc
        ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp
        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    LEFT JOIN catalog_returns cr
        ON cr.cr_order_number = cs.cs_order_number
        AND cr.cr_item_sk = cs.cs_item_sk
        AND cr.cr_returned_date_sk = cd.d_date_sk
        AND cr.cr_call_center_sk = cc.cc_call_center_sk
        AND cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    GROUP BY cd.d_year, cd.d_month_seq, cc.cc_division_name, cp.cp_type
),
web_sales_agg AS (
    SELECT
        wd.d_year,
        wd.d_month_seq,
        wp.wp_type AS page_type,
        SUM(ws.ws_net_paid) AS total_net_paid,
        SUM(ws.ws_net_profit) AS total_net_profit,
        SUM(COALESCE(wr.wr_net_loss, 0)) AS total_return_loss
    FROM web_sales ws
    JOIN date_dim wd
        ON ws.ws_sold_date_sk = wd.d_date_sk
    JOIN web_page wp
        ON ws.ws_web_page_sk = wp.wp_web_page_sk
    LEFT JOIN web_returns wr
        ON wr.wr_order_number = ws.ws_order_number
        AND wr.wr_item_sk = ws.ws_item_sk
        AND wr.wr_returned_date_sk = wd.d_date_sk
        AND wr.wr_web_page_sk = wp.wp_web_page_sk
    GROUP BY wd.d_year, wd.d_month_seq, wp.wp_type
),
combined AS (
    SELECT
        'catalog' AS channel,
        d_year,
        d_month_seq,
        division_name,
        page_type,
        total_net_paid,
        total_net_profit,
        total_return_loss,
        total_net_profit - total_return_loss AS net_profit_after_returns
    FROM catalog_sales_agg
    UNION ALL
    SELECT
        'web' AS channel,
        d_year,
        d_month_seq,
        NULL AS division_name,
        page_type,
        total_net_paid,
        total_net_profit,
        total_return_loss,
        total_net_profit - total_return_loss AS net_profit_after_returns
    FROM web_sales_agg
),
ranked AS (
    SELECT
        *,
        ROW_NUMBER() OVER (PARTITION BY channel ORDER BY net_profit_after_returns DESC) AS profit_rank
    FROM combined
)
SELECT
    channel,
    d_year,
    d_month_seq,
    division_name,
    page_type,
    total_net_paid,
    total_net_profit,
    total_return_loss,
    net_profit_after_returns,
    profit_rank
FROM ranked
ORDER BY channel, profit_rank
