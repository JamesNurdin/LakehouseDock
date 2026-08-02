WITH store_agg AS (
    SELECT
        COALESCE(d_s.d_date, d_r.d_date) AS sale_date,
        'store' AS channel,
        SUM(COALESCE(ss.ss_net_profit, 0) - COALESCE(sr.sr_net_loss, 0)) AS net_profit,
        COUNT(DISTINCT COALESCE(ss.ss_ticket_number, sr.sr_ticket_number)) AS total_orders,
        CASE WHEN SUM(COALESCE(ss.ss_net_profit, 0) - COALESCE(sr.sr_net_loss, 0)) > 0 THEN 'POSITIVE' ELSE 'NEGATIVE' END AS profit_category,
        COUNT(DISTINCT COALESCE(ss.ss_customer_sk, sr.sr_customer_sk)) AS distinct_customers
    FROM store_sales ss
    FULL OUTER JOIN store_returns sr
        ON ss.ss_ticket_number = sr.sr_ticket_number
    LEFT JOIN date_dim d_s
        ON ss.ss_sold_date_sk = d_s.d_date_sk
    LEFT JOIN date_dim d_r
        ON sr.sr_returned_date_sk = d_r.d_date_sk
    GROUP BY COALESCE(d_s.d_date, d_r.d_date)
),
web_agg AS (
    SELECT
        COALESCE(d_s.d_date, d_r.d_date) AS sale_date,
        'web' AS channel,
        SUM(COALESCE(ws.ws_net_profit, 0) - COALESCE(wr.wr_net_loss, 0)) AS net_profit,
        COUNT(DISTINCT COALESCE(ws.ws_order_number, wr.wr_order_number)) AS total_orders,
        CASE WHEN SUM(COALESCE(ws.ws_net_profit, 0) - COALESCE(wr.wr_net_loss, 0)) > 0 THEN 'POSITIVE' ELSE 'NEGATIVE' END AS profit_category,
        COUNT(DISTINCT COALESCE(ws.ws_bill_customer_sk, wr.wr_refunded_customer_sk)) AS distinct_customers
    FROM web_sales ws
    FULL OUTER JOIN web_returns wr
        ON ws.ws_order_number = wr.wr_order_number
    LEFT JOIN date_dim d_s
        ON ws.ws_sold_date_sk = d_s.d_date_sk
    LEFT JOIN date_dim d_r
        ON wr.wr_returned_date_sk = d_r.d_date_sk
    GROUP BY COALESCE(d_s.d_date, d_r.d_date)
)
SELECT DISTINCT
    agg.sale_date,
    agg.channel,
    agg.net_profit,
    agg.total_orders,
    agg.profit_category,
    agg.distinct_customers,
    (
        SELECT COUNT(DISTINCT p.p_promo_sk)
        FROM promotion p
        JOIN date_dim pd
            ON pd.d_date = agg.sale_date
               AND pd.d_date_sk BETWEEN p.p_start_date_sk AND p.p_end_date_sk
    ) AS active_promotions
FROM (
    SELECT * FROM store_agg
    UNION ALL
    SELECT * FROM web_agg
) AS agg
ORDER BY agg.net_profit DESC, agg.sale_date DESC
LIMIT 100
