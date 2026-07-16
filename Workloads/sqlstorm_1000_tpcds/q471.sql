WITH
    store_sales_agg AS (
        SELECT
            d.d_date_sk,
            d.d_date,
            d.d_year,
            d.d_month_seq,
            'store' AS channel,
            COALESCE(s.s_store_sk, -1) AS entity_sk,
            COALESCE(NULLIF(TRIM(s.s_store_name), ''), 'UNKNOWN') AS entity_name,
            SUM(ss.ss_net_paid) AS total_net_paid,
            SUM(ss.ss_net_profit) AS total_net_profit,
            SUM(ss.ss_quantity) AS total_quantity,
            COUNT(DISTINCT ss.ss_ticket_number) AS transaction_count,
            SUM(ss.ss_ext_discount_amt) AS total_discount,
            MAX(ss.ss_net_paid) AS max_net_paid
        FROM store_sales ss
        JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
        LEFT JOIN store s ON ss.ss_store_sk = s.s_store_sk
        GROUP BY
            d.d_date_sk, d.d_date, d.d_year, d.d_month_seq,
            s.s_store_sk, s.s_store_name
    ),
    catalog_sales_agg AS (
        SELECT
            d.d_date_sk,
            d.d_date,
            d.d_year,
            d.d_month_seq,
            'catalog' AS channel,
            COALESCE(c.cc_call_center_sk, -1) AS entity_sk,
            COALESCE(NULLIF(TRIM(c.cc_name), ''), 'UNKNOWN') AS entity_name,
            SUM(cs.cs_net_paid) AS total_net_paid,
            SUM(cs.cs_net_profit) AS total_net_profit,
            SUM(cs.cs_quantity) AS total_quantity,
            COUNT(DISTINCT cs.cs_order_number) AS transaction_count,
            SUM(cs.cs_ext_discount_amt) AS total_discount,
            MAX(cs.cs_net_paid) AS max_net_paid
        FROM catalog_sales cs
        JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
        LEFT JOIN call_center c ON cs.cs_call_center_sk = c.cc_call_center_sk
        GROUP BY
            d.d_date_sk, d.d_date, d.d_year, d.d_month_seq,
            c.cc_call_center_sk, c.cc_name
    ),
    web_sales_agg AS (
        SELECT
            d.d_date_sk,
            d.d_date,
            d.d_year,
            d.d_month_seq,
            'web' AS channel,
            COALESCE(wp.wp_web_page_sk, -1) AS entity_sk,
            COALESCE(NULLIF(TRIM(wp.wp_url), ''), 'UNKNOWN') AS entity_name,
            SUM(ws.ws_net_paid) AS total_net_paid,
            SUM(ws.ws_net_profit) AS total_net_profit,
            SUM(ws.ws_quantity) AS total_quantity,
            COUNT(DISTINCT ws.ws_order_number) AS transaction_count,
            SUM(ws.ws_ext_discount_amt) AS total_discount,
            MAX(ws.ws_net_paid) AS max_net_paid
        FROM web_sales ws
        JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
        LEFT JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
        GROUP BY
            d.d_date_sk, d.d_date, d.d_year, d.d_month_seq,
            wp.wp_web_page_sk, wp.wp_url
    ),
    all_sales AS (
        SELECT * FROM store_sales_agg
        UNION ALL
        SELECT * FROM catalog_sales_agg
        UNION ALL
        SELECT * FROM web_sales_agg
    ),
    returns_agg AS (
        SELECT
            d.d_date_sk,
            d.d_date,
            CASE
                WHEN sr.sr_store_sk IS NOT NULL THEN 'store'
                WHEN cr.cr_call_center_sk IS NOT NULL THEN 'catalog'
                WHEN wr.wr_web_page_sk IS NOT NULL THEN 'web'
                ELSE 'unknown'
            END AS channel,
            COALESCE(sr.sr_store_sk,
                     cr.cr_call_center_sk,
                     wr.wr_web_page_sk,
                     -1) AS entity_sk,
            SUM(COALESCE(sr.sr_net_loss, 0) +
                COALESCE(cr.cr_net_loss, 0) +
                COALESCE(wr.wr_net_loss, 0)) AS total_net_loss,
            COUNT(
                CASE
                    WHEN COALESCE(sr.sr_return_quantity,
                                  cr.cr_return_quantity,
                                  wr.wr_return_quantity) > 0 THEN 1
                END
            ) AS return_transactions
        FROM date_dim d
        LEFT JOIN store_returns sr ON sr.sr_returned_date_sk = d.d_date_sk
        LEFT JOIN catalog_returns cr ON cr.cr_returned_date_sk = d.d_date_sk
        LEFT JOIN web_returns wr ON wr.wr_returned_date_sk = d.d_date_sk
        GROUP BY
            d.d_date_sk, d.d_date,
            CASE
                WHEN sr.sr_store_sk IS NOT NULL THEN 'store'
                WHEN cr.cr_call_center_sk IS NOT NULL THEN 'catalog'
                WHEN wr.wr_web_page_sk IS NOT NULL THEN 'web'
                ELSE 'unknown'
            END,
            COALESCE(sr.sr_store_sk,
                     cr.cr_call_center_sk,
                     wr.wr_web_page_sk,
                     -1)
    ),
    combined AS (
        SELECT
            a.d_date_sk,
            a.d_date,
            a.channel,
            a.entity_sk,
            a.entity_name,
            a.total_net_paid,
            a.total_net_profit,
            a.total_quantity,
            a.transaction_count,
            a.total_discount,
            a.max_net_paid,
            COALESCE(r.total_net_loss, 0) AS total_net_loss,
            COALESCE(r.return_transactions, 0) AS return_transactions
        FROM all_sales a
        LEFT JOIN returns_agg r
            ON a.d_date_sk = r.d_date_sk
            AND a.channel = r.channel
            AND a.entity_sk = r.entity_sk
    ),
    ranked AS (
        SELECT
            c.*,
            ROW_NUMBER() OVER (PARTITION BY c.d_date_sk ORDER BY c.total_net_profit DESC) AS profit_rank,
            LAG(c.total_net_profit) OVER (PARTITION BY c.d_date_sk ORDER BY c.total_net_profit DESC) AS prev_profit,
            SUM(c.total_net_profit) OVER (PARTITION BY c.channel ORDER BY c.d_date) AS cumulative_profit,
            CASE
                WHEN c.total_net_paid = 0 THEN NULL
                ELSE c.total_net_profit / NULLIF(c.total_net_paid, 0)
            END AS profit_margin,
            CASE
                WHEN c.entity_name IS NULL OR c.entity_name = '' THEN 'NO_NAME'
                ELSE c.entity_name
            END AS safe_entity_name,
            CONCAT(c.channel, ':', COALESCE(c.entity_name, 'UNKNOWN')) AS channel_entity_key,
            CASE
                WHEN c.total_net_profit > 0 AND c.total_net_loss > 0 AND c.total_net_profit > c.total_net_loss THEN 'POSITIVE'
                WHEN c.total_net_profit < 0 AND c.total_net_loss > 0 THEN 'NEGATIVE'
                ELSE 'NEUTRAL'
            END AS profit_status,
            CASE
                WHEN RAND() < 0.0001 THEN NULL
                ELSE c.total_discount
            END AS maybe_null_discount
        FROM combined c
    ),
    enriched AS (
        SELECT
            r.*,
            (SELECT MAX(inner_r.total_net_profit)
             FROM ranked inner_r
             WHERE inner_r.d_date_sk = r.d_date_sk) AS max_profit_same_date,
            (SELECT COUNT(*)
             FROM ranked inner_r2
             WHERE inner_r2.d_date_sk = r.d_date_sk
               AND inner_r2.profit_status = 'POSITIVE') AS positive_profit_count,
            CASE
                WHEN r.profit_margin IS NOT NULL AND r.profit_margin > 0.5 THEN 'HIGH_MARGIN'
                WHEN r.profit_margin IS NOT NULL AND r.profit_margin < 0.1 THEN 'LOW_MARGIN'
                ELSE 'MEDIUM_MARGIN'
            END AS margin_category
        FROM ranked r
    )
SELECT
    e.d_date,
    e.channel,
    e.entity_sk,
    e.safe_entity_name,
    e.total_net_paid,
    e.total_net_profit,
    e.profit_margin,
    e.profit_status,
    e.margin_category,
    e.profit_rank,
    e.prev_profit,
    e.cumulative_profit,
    e.return_transactions,
    e.total_net_loss,
    e.channel_entity_key
FROM enriched e
WHERE
    (e.total_net_profit > 0 AND e.return_transactions = 0)
    OR (e.channel = 'catalog' AND e.profit_margin > 0.2)
    AND e.profit_rank <= 5
ORDER BY e.d_date DESC, e.profit_rank
