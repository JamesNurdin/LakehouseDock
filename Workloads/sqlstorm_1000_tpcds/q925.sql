WITH date_cte AS (
    SELECT d_date_sk, d_date, d_year
    FROM date_dim
    WHERE d_year BETWEEN 1998 AND 1999
),
sales_agg AS (
    SELECT
        d.d_date,
        COALESCE(cs.cs_net_profit, 0) + COALESCE(ss.ss_net_profit, 0) + COALESCE(ws.ws_net_profit, 0) AS total_profit,
        COALESCE(cs.cs_quantity, 0) + COALESCE(ss.ss_quantity, 0) + COALESCE(ws.ws_quantity, 0) AS total_quantity,
        CASE
            WHEN COALESCE(cs.cs_net_paid, 0) > 0 THEN 'C'
            WHEN COALESCE(ss.ss_net_paid, 0) > 0 THEN 'S'
            WHEN COALESCE(ws.ws_net_paid, 0) > 0 THEN 'W'
            ELSE 'U'
        END AS primary_channel,
        ROW_NUMBER() OVER (PARTITION BY d.d_date ORDER BY (COALESCE(cs.cs_net_profit,0) + COALESCE(ss.ss_net_profit,0) + COALESCE(ws.ws_net_profit,0)) DESC) AS profit_rank,
        CONCAT(COALESCE(cc.cc_call_center_id, 'NOCC'), '-', COALESCE(CAST(d.d_date AS VARCHAR), 'NODATE')) AS unique_key
    FROM date_cte d
    LEFT JOIN catalog_sales cs ON cs.cs_sold_date_sk = d.d_date_sk
    LEFT JOIN store_sales ss ON ss.ss_sold_date_sk = d.d_date_sk
    LEFT JOIN web_sales ws ON ws.ws_sold_date_sk = d.d_date_sk
    LEFT JOIN call_center cc ON cc.cc_call_center_sk = cs.cs_call_center_sk
    WHERE d.d_year = 1999 OR d.d_year IS NULL
),
revenue_by_promo AS (
    SELECT
        p.p_promo_id,
        COALESCE(SUM(cs.cs_net_paid_inc_tax), 0) AS catalog_rev,
        COALESCE(SUM(ss.ss_net_paid_inc_tax), 0) AS store_rev,
        COALESCE(SUM(ws.ws_net_paid_inc_tax), 0) AS web_rev,
        COALESCE(SUM(cs.cs_net_paid_inc_tax), 0) + COALESCE(SUM(ss.ss_net_paid_inc_tax), 0) + COALESCE(SUM(ws.ws_net_paid_inc_tax), 0) AS total_rev,
        ROW_NUMBER() OVER (ORDER BY (COALESCE(SUM(cs.cs_net_paid_inc_tax), 0) + COALESCE(SUM(ss.ss_net_paid_inc_tax), 0) + COALESCE(SUM(ws.ws_net_paid_inc_tax), 0)) DESC) AS rev_rank
    FROM promotion p
    LEFT JOIN catalog_sales cs ON cs.cs_promo_sk = p.p_promo_sk
    LEFT JOIN store_sales ss ON ss.ss_promo_sk = p.p_promo_sk
    LEFT JOIN web_sales ws ON ws.ws_promo_sk = p.p_promo_sk
    GROUP BY p.p_promo_id
),
top_promo AS (
    SELECT
        p.p_promo_id,
        p.p_promo_name,
        p.p_discount_active
    FROM promotion p
    WHERE p.p_discount_active = 'Y'
      AND NOT EXISTS (
          SELECT 1 FROM revenue_by_promo r WHERE r.p_promo_id = p.p_promo_id AND r.total_rev < 10000
      )
),
combined_sales_returns AS (
    SELECT
        cs.cs_order_number AS order_no,
        cs.cs_sold_date_sk AS d_date_sk,
        'sale' AS typ,
        cs.cs_quantity AS qty,
        cs.cs_net_paid AS net_paid,
        cs.cs_net_profit AS profit
    FROM catalog_sales cs
    UNION ALL
    SELECT
        cr.cr_order_number,
        cr.cr_returned_date_sk,
        'return',
        -cr.cr_return_quantity,
        -cr.cr_return_amt_inc_tax,
        -cr.cr_net_loss
    FROM catalog_returns cr
    UNION ALL
    SELECT
        ss.ss_ticket_number,
        ss.ss_sold_date_sk,
        'sale',
        ss.ss_quantity,
        ss.ss_net_paid,
        ss.ss_net_profit
    FROM store_sales ss
    UNION ALL
    SELECT
        sr.sr_ticket_number,
        sr.sr_returned_date_sk,
        'return',
        -sr.sr_return_quantity,
        -sr.sr_return_amt_inc_tax,
        -sr.sr_net_loss
    FROM store_returns sr
    UNION ALL
    SELECT
        ws.ws_order_number,
        ws.ws_sold_date_sk,
        'sale',
        ws.ws_quantity,
        ws.ws_net_paid,
        ws.ws_net_profit
    FROM web_sales ws
    UNION ALL
    SELECT
        wr.wr_order_number,
        wr.wr_returned_date_sk,
        'return',
        -wr.wr_return_quantity,
        -wr.wr_return_amt_inc_tax,
        -wr.wr_net_loss
    FROM web_returns wr
),
daily_balances AS (
    SELECT
        d.d_date,
        COALESCE(SUM(CASE WHEN cr.typ = 'sale' THEN cr.net_paid ELSE 0 END), 0) - COALESCE(SUM(CASE WHEN cr.typ = 'return' THEN cr.net_paid ELSE 0 END), 0) AS net_cash_flow,
        COALESCE(SUM(CASE WHEN cr.typ = 'sale' THEN cr.profit ELSE 0 END), 0) - COALESCE(SUM(CASE WHEN cr.typ = 'return' THEN cr.profit ELSE 0 END), 0) AS net_profit,
        COUNT(DISTINCT cr.order_no) AS distinct_orders
    FROM date_cte d
    LEFT JOIN combined_sales_returns cr ON cr.d_date_sk = d.d_date_sk
    GROUP BY d.d_date
)
SELECT
    db.d_date,
    db.net_cash_flow,
    db.net_profit,
    db.distinct_orders,
    sa.total_profit,
    sa.total_quantity,
    sa.primary_channel,
    sa.profit_rank,
    rp.p_promo_id,
    rp.total_rev,
    rp.rev_rank,
    tp.p_promo_name,
    tp.p_discount_active,
    CASE
        WHEN rp.rev_rank <= 5 THEN 'Top5'
        WHEN rp.rev_rank <= 10 THEN 'Top10'
        ELSE 'Other'
    END AS promo_bucket,
    (SELECT AVG(db2.net_profit)
     FROM daily_balances db2
     WHERE db2.d_date >= DATE_TRUNC('month', db.d_date)
       AND db2.d_date < DATE_TRUNC('month', db.d_date) + INTERVAL '1' MONTH) AS avg_monthly_profit,
    SUM(db.net_profit) OVER (ORDER BY db.d_date ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cum_profit,
    COALESCE(sa.unique_key, CONCAT('UNKNOWN-', CAST(db.d_date AS VARCHAR))) AS unique_key,
    array_join(array_agg(DISTINCT rp.p_promo_id) FILTER (WHERE rp.p_promo_id IS NOT NULL), ',') AS promos_on_day,
    CASE
        WHEN db.net_cash_flow > 0 THEN TRUE
        WHEN db.net_cash_flow = 0 THEN NULL
        ELSE FALSE
    END AS cash_flow_positive
FROM daily_balances db
LEFT JOIN sales_agg sa ON sa.d_date = db.d_date
LEFT JOIN revenue_by_promo rp ON rp.p_promo_id = (
    SELECT p.p_promo_id
    FROM top_promo p
    ORDER BY rand()
    LIMIT 1
)
LEFT JOIN top_promo tp ON tp.p_promo_id = rp.p_promo_id
WHERE db.net_profit IS NOT NULL
  AND (db.net_cash_flow IS NULL OR db.net_cash_flow <> 0)
GROUP BY
    db.d_date,
    db.net_cash_flow,
    db.net_profit,
    db.distinct_orders,
    sa.total_profit,
    sa.total_quantity,
    sa.primary_channel,
    sa.profit_rank,
    rp.p_promo_id,
    rp.total_rev,
    rp.rev_rank,
    tp.p_promo_name,
    tp.p_discount_active,
    sa.unique_key
HAVING SUM(db.net_profit) > 0
ORDER BY db.d_date DESC
LIMIT 100
