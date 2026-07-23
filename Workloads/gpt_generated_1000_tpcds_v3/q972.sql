WITH base AS (
    SELECT
        ss.ss_store_sk,
        ss.ss_item_sk,
        ss.ss_ticket_number,
        ss.ss_sales_price,
        ss.ss_net_paid,
        ss.ss_net_profit,
        p.p_promo_id,
        p.p_discount_active,
        td.t_shift,
        cd.cd_credit_rating,
        cd.cd_dep_count,
        r_sr.r_reason_desc AS store_return_reason,
        sr.sr_net_loss AS store_return_net_loss,
        wr.wr_net_loss AS web_return_net_loss,
        CASE WHEN cd.cd_credit_rating = 'High Risk' THEN 'Risky' ELSE 'Not Risky' END AS risk_category,
        (SELECT COUNT(*) FROM store_sales ss2 WHERE ss2.ss_promo_sk = ss.ss_promo_sk) AS promo_transaction_cnt
    FROM store_sales ss
    JOIN time_dim td ON ss.ss_sold_time_sk = td.t_time_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN store_returns sr ON sr.sr_item_sk = ss.ss_item_sk AND sr.sr_ticket_number = ss.ss_ticket_number
    LEFT JOIN reason r_sr ON sr.sr_reason_sk = r_sr.r_reason_sk
    LEFT JOIN web_returns wr ON wr.wr_item_sk = ss.ss_item_sk AND wr.wr_returned_time_sk = td.t_time_sk
    LEFT JOIN reason r_wr ON wr.wr_reason_sk = r_wr.r_reason_sk
    WHERE
        td.t_shift = 'first'
        AND cd.cd_credit_rating = 'High Risk'
        AND p.p_discount_active = 'Y'
        AND ss.ss_sales_price > 100
        AND (sr.sr_store_credit > 200 OR wr.wr_net_loss > 0)
        AND r_sr.r_reason_desc LIKE '%damaged%'
),
agg AS (
    SELECT
        ss_store_sk,
        p_promo_id,
        risk_category,
        SUM(ss_net_profit) AS total_net_profit,
        SUM(store_return_net_loss) AS total_store_return_loss,
        SUM(web_return_net_loss) AS total_web_return_loss,
        COUNT(DISTINCT ss_ticket_number) AS distinct_tickets,
        AVG(promo_transaction_cnt) AS avg_promo_txn_cnt
    FROM base
    GROUP BY ss_store_sk, p_promo_id, risk_category
    HAVING SUM(ss_net_profit) > 0
)
SELECT
    ss_store_sk,
    p_promo_id,
    risk_category,
    total_net_profit,
    total_store_return_loss,
    total_web_return_loss,
    distinct_tickets,
    avg_promo_txn_cnt,
    RANK() OVER (PARTITION BY ss_store_sk ORDER BY total_net_profit DESC) AS profit_rank_by_store,
    SUM(total_net_profit) OVER (PARTITION BY ss_store_sk ORDER BY total_net_profit ROWS BETWEEN 2 PRECEDING AND CURRENT ROW) AS rolling_sum_profit
FROM agg
ORDER BY total_net_profit DESC
LIMIT 100
