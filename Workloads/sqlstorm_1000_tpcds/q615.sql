WITH unified AS (
    SELECT
        'store' AS channel,
        ss.ss_sold_date_sk AS date_sk,
        i.i_category,
        i.i_brand,
        s.s_state AS state,
        ss.ss_quantity AS quantity,
        ss.ss_net_paid AS net_amount,
        ss.ss_net_profit AS net_profit,
        'sale' AS txn_type
    FROM store_sales ss
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk

    UNION ALL

    SELECT
        'store',
        sr.sr_returned_date_sk,
        i.i_category,
        i.i_brand,
        s.s_state,
        sr.sr_return_quantity,
        -sr.sr_return_amt_inc_tax,
        -sr.sr_net_loss,
        'return'
    FROM store_returns sr
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    JOIN store s ON sr.sr_store_sk = s.s_store_sk

    UNION ALL

    SELECT
        'web',
        ws.ws_sold_date_sk,
        i.i_category,
        i.i_brand,
        w.web_state,
        ws.ws_quantity,
        ws.ws_net_paid,
        ws.ws_net_profit,
        'sale'
    FROM web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN web_site w ON ws.ws_web_site_sk = w.web_site_sk

    UNION ALL

    SELECT
        'web',
        wr.wr_returned_date_sk,
        i.i_category,
        i.i_brand,
        CAST(NULL AS varchar),
        wr.wr_return_quantity,
        -wr.wr_return_amt_inc_tax,
        -wr.wr_net_loss,
        'return'
    FROM web_returns wr
    JOIN item i ON wr.wr_item_sk = i.i_item_sk

    UNION ALL

    SELECT
        'catalog',
        cs.cs_sold_date_sk,
        i.i_category,
        i.i_brand,
        cc.cc_state,
        cs.cs_quantity,
        cs.cs_net_paid,
        cs.cs_net_profit,
        'sale'
    FROM catalog_sales cs
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk

    UNION ALL

    SELECT
        'catalog',
        cr.cr_returned_date_sk,
        i.i_category,
        i.i_brand,
        cc.cc_state,
        cr.cr_return_quantity,
        -cr.cr_return_amt_inc_tax,
        -cr.cr_net_loss,
        'return'
    FROM catalog_returns cr
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
),
aggregated AS (
    SELECT
        u.channel,
        d.d_year AS year,
        d.d_month_seq AS month,
        u.i_category,
        u.i_brand,
        u.state,
        SUM(CASE WHEN u.txn_type = 'sale' THEN u.quantity ELSE 0 END) AS total_quantity_sold,
        SUM(CASE WHEN u.txn_type = 'sale' THEN u.net_amount ELSE 0 END) AS total_sales_amount,
        SUM(CASE WHEN u.txn_type = 'sale' THEN u.net_profit ELSE 0 END) AS total_sales_profit,
        SUM(CASE WHEN u.txn_type = 'return' THEN u.quantity ELSE 0 END) AS total_quantity_returned,
        SUM(CASE WHEN u.txn_type = 'return' THEN u.net_amount ELSE 0 END) AS total_return_amount,
        SUM(CASE WHEN u.txn_type = 'return' THEN u.net_amount ELSE 0 END) /
            NULLIF(SUM(CASE WHEN u.txn_type = 'sale' THEN u.net_amount ELSE 0 END), 0) AS return_loss_ratio,
        ROW_NUMBER() OVER (PARTITION BY u.channel ORDER BY SUM(CASE WHEN u.txn_type = 'sale' THEN u.net_profit ELSE 0 END) DESC) AS profit_rank
    FROM unified u
    JOIN date_dim d ON u.date_sk = d.d_date_sk
    GROUP BY
        u.channel,
        d.d_year,
        d.d_month_seq,
        u.i_category,
        u.i_brand,
        u.state
)
SELECT
    channel,
    year,
    month,
    i_category,
    i_brand,
    state,
    total_quantity_sold,
    total_sales_amount,
    total_sales_profit,
    total_quantity_returned,
    total_return_amount,
    return_loss_ratio,
    profit_rank
FROM aggregated
ORDER BY channel, year, month, profit_rank
