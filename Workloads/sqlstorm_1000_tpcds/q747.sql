WITH combined_sales AS (
    SELECT
        d.d_date_sk AS date_sk,
        d.d_year,
        'store' AS channel,
        s.s_state AS state,
        i.i_category,
        ss.ss_quantity AS quantity,
        ss.ss_net_paid AS net_paid,
        ss.ss_net_profit AS net_profit,
        COALESCE(sr.sr_return_quantity, 0) AS return_qty,
        COALESCE(sr.sr_return_amt, 0) AS return_amt
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    LEFT JOIN store_returns sr ON ss.ss_ticket_number = sr.sr_ticket_number

    UNION ALL

    SELECT
        d.d_date_sk,
        d.d_year,
        'catalog' AS channel,
        w.w_state AS state,
        i.i_category,
        cs.cs_quantity,
        cs.cs_net_paid,
        cs.cs_net_profit,
        COALESCE(cr.cr_return_quantity, 0) AS return_qty,
        COALESCE(cr.cr_return_amount, 0) AS return_amt
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    LEFT JOIN catalog_returns cr ON cs.cs_order_number = cr.cr_order_number

    UNION ALL

    SELECT
        d.d_date_sk,
        d.d_year,
        'web' AS channel,
        ws_site.web_state AS state,
        i.i_category,
        ws.ws_quantity,
        ws.ws_net_paid,
        ws.ws_net_profit,
        COALESCE(wr.wr_return_quantity, 0) AS return_qty,
        COALESCE(wr.wr_return_amt, 0) AS return_amt
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN web_site ws_site ON ws.ws_web_site_sk = ws_site.web_site_sk
    LEFT JOIN web_returns wr ON ws.ws_order_number = wr.wr_order_number
),
agg AS (
    SELECT
        d_year,
        state,
        i_category,
        channel,
        SUM(quantity) AS total_quantity,
        SUM(net_paid) AS total_net_paid,
        SUM(net_profit) AS total_net_profit,
        SUM(return_qty) AS total_return_qty,
        SUM(return_amt) AS total_return_amt,
        SUM(net_paid) / NULLIF(SUM(quantity), 0) AS avg_spent_per_item
    FROM combined_sales
    WHERE d_year BETWEEN 2000 AND 2002
    GROUP BY GROUPING SETS (
        (d_year, state, i_category, channel),
        (d_year, i_category, channel),
        (state, i_category, channel),
        (i_category, channel),
        (d_year, state, i_category),
        (d_year, state),
        (state),
        ()
    )
    HAVING SUM(net_profit) > 0
)
SELECT
    d_year,
    state,
    i_category,
    channel,
    total_quantity,
    total_net_paid,
    total_net_profit,
    total_return_qty,
    total_return_amt,
    avg_spent_per_item,
    RANK() OVER (PARTITION BY i_category ORDER BY total_net_profit DESC) AS profit_rank
FROM agg
ORDER BY d_year, state, i_category, channel
