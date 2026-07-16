WITH base_sales AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        i.i_category,
        i.i_category_id,
        i.i_brand,
        i.i_brand_id,
        i.i_item_id,
        s.s_state AS store_state,
        'store' AS channel,
        ss.ss_quantity AS quantity,
        ss.ss_net_paid AS net_paid,
        ss.ss_net_profit AS net_profit,
        ss.ss_ticket_number AS ticket_number
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    LEFT JOIN store s ON ss.ss_store_sk = s.s_store_sk
    WHERE d.d_year BETWEEN 2000 AND 2002
), base_catalog AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        i.i_category,
        i.i_category_id,
        i.i_brand,
        i.i_brand_id,
        i.i_item_id,
        CAST(NULL AS VARCHAR) AS store_state,
        'catalog' AS channel,
        cs.cs_quantity AS quantity,
        cs.cs_net_paid AS net_paid,
        cs.cs_net_profit AS net_profit,
        cs.cs_order_number AS ticket_number
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    WHERE d.d_year BETWEEN 2000 AND 2002
), base_web AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        i.i_category,
        i.i_category_id,
        i.i_brand,
        i.i_brand_id,
        i.i_item_id,
        CAST(NULL AS VARCHAR) AS store_state,
        'web' AS channel,
        ws.ws_quantity AS quantity,
        ws.ws_net_paid AS net_paid,
        ws.ws_net_profit AS net_profit,
        ws.ws_order_number AS ticket_number
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    WHERE d.d_year BETWEEN 2000 AND 2002
), combined_sales AS (
    SELECT * FROM base_sales
    UNION ALL
    SELECT * FROM base_catalog
    UNION ALL
    SELECT * FROM base_web
), returns AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        i.i_category,
        'store' AS channel,
        sr.sr_return_quantity AS quantity,
        sr.sr_return_amt AS amount,
        sr.sr_net_loss AS net_loss
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    UNION ALL
    SELECT
        d.d_year,
        d.d_month_seq,
        i.i_category,
        'catalog' AS channel,
        cr.cr_return_quantity AS quantity,
        cr.cr_return_amount AS amount,
        cr.cr_net_loss AS net_loss
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    UNION ALL
    SELECT
        d.d_year,
        d.d_month_seq,
        i.i_category,
        'web' AS channel,
        wr.wr_return_quantity AS quantity,
        wr.wr_return_amt AS amount,
        wr.wr_net_loss AS net_loss
    FROM web_returns wr
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN item i ON wr.wr_item_sk = i.i_item_sk
), agg_sales AS (
    SELECT
        d_year,
        d_month_seq,
        i_category,
        channel,
        SUM(quantity) AS total_quantity,
        SUM(net_paid) AS total_net_paid,
        SUM(net_profit) AS total_net_profit
    FROM combined_sales
    GROUP BY d_year, d_month_seq, i_category, channel
), agg_returns AS (
    SELECT
        d_year,
        d_month_seq,
        i_category,
        channel,
        SUM(quantity) AS total_return_quantity,
        SUM(amount) AS total_return_amount,
        SUM(net_loss) AS total_net_loss
    FROM returns
    GROUP BY d_year, d_month_seq, i_category, channel
)
SELECT
    s.d_year,
    s.d_month_seq,
    s.i_category,
    s.channel,
    s.total_quantity,
    s.total_net_paid,
    s.total_net_profit,
    r.total_return_quantity,
    r.total_return_amount,
    r.total_net_loss,
    s.total_net_profit - COALESCE(r.total_net_loss, 0) AS net_profit_after_returns,
    ROUND(100.0 * (s.total_net_profit - COALESCE(r.total_net_loss, 0)) / NULLIF(s.total_net_profit, 0), 2) AS profit_margin_pct,
    SUM(s.total_net_profit) OVER (PARTITION BY s.channel ORDER BY s.d_year, s.d_month_seq ROWS UNBOUNDED PRECEDING) AS running_profit
FROM agg_sales s
LEFT JOIN agg_returns r
    ON s.d_year = r.d_year
    AND s.d_month_seq = r.d_month_seq
    AND s.i_category = r.i_category
    AND s.channel = r.channel
ORDER BY s.channel, s.d_year, s.d_month_seq, s.i_category
