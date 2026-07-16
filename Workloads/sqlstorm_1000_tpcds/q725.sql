WITH daily_sales AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        f.channel,
        f.category,
        SUM(f.net_paid_inc_tax) AS total_sales,
        SUM(f.net_profit) AS total_profit,
        COUNT(DISTINCT f.transaction_id) AS num_orders
    FROM (
        SELECT
            cs.cs_sold_date_sk AS date_sk,
            cs.cs_order_number AS transaction_id,
            cs.cs_net_paid_inc_tax AS net_paid_inc_tax,
            cs.cs_net_profit AS net_profit,
            'catalog' AS channel,
            i.i_category AS category
        FROM catalog_sales cs
        JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
        JOIN item i ON cs.cs_item_sk = i.i_item_sk
        WHERE p.p_discount_active = 'Y'
          AND cs.cs_sold_date_sk BETWEEN p.p_start_date_sk AND p.p_end_date_sk

        UNION ALL

        SELECT
            ss.ss_sold_date_sk,
            ss.ss_ticket_number,
            ss.ss_net_paid_inc_tax,
            ss.ss_net_profit,
            'store' AS channel,
            i.i_category
        FROM store_sales ss
        JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
        JOIN item i ON ss.ss_item_sk = i.i_item_sk
        WHERE p.p_discount_active = 'Y'
          AND ss.ss_sold_date_sk BETWEEN p.p_start_date_sk AND p.p_end_date_sk

        UNION ALL

        SELECT
            ws.ws_sold_date_sk,
            ws.ws_order_number,
            ws.ws_net_paid_inc_tax,
            ws.ws_net_profit,
            'web' AS channel,
            i.i_category
        FROM web_sales ws
        JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
        JOIN item i ON ws.ws_item_sk = i.i_item_sk
        WHERE p.p_discount_active = 'Y'
          AND ws.ws_sold_date_sk BETWEEN p.p_start_date_sk AND p.p_end_date_sk
    ) f
    JOIN date_dim d ON f.date_sk = d.d_date_sk
    GROUP BY d.d_year, d.d_month_seq, f.channel, f.category
), daily_returns AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        r.channel,
        r.category,
        SUM(r.net_loss) AS total_loss,
        COUNT(DISTINCT r.return_id) AS num_returns
    FROM (
        SELECT
            cr.cr_returned_date_sk AS date_sk,
            cr.cr_order_number AS return_id,
            cr.cr_net_loss AS net_loss,
            'catalog' AS channel,
            i.i_category AS category
        FROM catalog_returns cr
        JOIN item i ON cr.cr_item_sk = i.i_item_sk

        UNION ALL

        SELECT
            sr.sr_returned_date_sk,
            sr.sr_ticket_number,
            sr.sr_net_loss,
            'store' AS channel,
            i.i_category
        FROM store_returns sr
        JOIN item i ON sr.sr_item_sk = i.i_item_sk

        UNION ALL

        SELECT
            wr.wr_returned_date_sk,
            wr.wr_order_number,
            wr.wr_net_loss,
            'web' AS channel,
            i.i_category
        FROM web_returns wr
        JOIN item i ON wr.wr_item_sk = i.i_item_sk
    ) r
    JOIN date_dim d ON r.date_sk = d.d_date_sk
    GROUP BY d.d_year, d.d_month_seq, r.channel, r.category
)
SELECT
    ds.d_year,
    ds.channel,
    ds.category,
    ds.d_month_seq,
    ds.total_sales,
    ds.total_profit,
    COALESCE(dr.total_loss, 0) AS total_loss,
    ds.total_sales - COALESCE(dr.total_loss, 0) AS net_sales,
    CASE WHEN ds.total_sales <> 0 THEN ds.total_profit / ds.total_sales ELSE NULL END AS profit_margin,
    SUM(ds.total_profit) OVER (PARTITION BY ds.d_year) AS year_total_profit,
    CASE WHEN SUM(ds.total_profit) OVER (PARTITION BY ds.d_year) <> 0 THEN 100.0 * ds.total_profit / SUM(ds.total_profit) OVER (PARTITION BY ds.d_year) ELSE NULL END AS profit_pct_of_year,
    RANK() OVER (PARTITION BY ds.d_year ORDER BY ds.total_profit DESC) AS profit_rank
FROM daily_sales ds
LEFT JOIN daily_returns dr
    ON ds.d_year = dr.d_year
    AND ds.d_month_seq = dr.d_month_seq
    AND ds.channel = dr.channel
    AND ds.category = dr.category
WHERE ds.total_sales > 10000
ORDER BY ds.d_year, ds.channel, ds.category, profit_rank
LIMIT 200
