WITH
    base_data AS (
        SELECT
            s.s_store_sk AS s_store_sk,
            s.s_state AS s_state,
            p.p_promo_name AS p_promo_name,
            r.r_reason_desc AS r_reason_desc,
            t.t_hour AS t_hour,
            ss.ss_net_paid AS ss_net_paid,
            ss.ss_net_profit AS ss_net_profit,
            sr.sr_return_amt AS sr_return_amt,
            sr.sr_net_loss AS sr_net_loss,
            wr.wr_return_amt AS wr_return_amt
        FROM store_sales ss
        JOIN time_dim t
            ON ss.ss_sold_time_sk = t.t_time_sk
        JOIN store s
            ON ss.ss_store_sk = s.s_store_sk
        JOIN promotion p
            ON ss.ss_promo_sk = p.p_promo_sk
        JOIN store_returns sr
            ON ss.ss_ticket_number = sr.sr_ticket_number
            AND ss.ss_item_sk = sr.sr_item_sk
            AND sr.sr_store_sk = s.s_store_sk
        JOIN reason r
            ON sr.sr_reason_sk = r.r_reason_sk
        JOIN web_returns wr
            ON wr.wr_reason_sk = r.r_reason_sk
            AND wr.wr_returned_time_sk = t.t_time_sk
        WHERE t.t_hour IN (9, 14)
          AND s.s_state = 'TX'
          AND p.p_discount_active = 'Y'
          AND r.r_reason_desc LIKE '%damaged%'
          AND NOT EXISTS (
              SELECT 1
              FROM store_returns sr2
              WHERE sr2.sr_store_sk = s.s_store_sk
                AND sr2.sr_net_loss > 2000
          )
    ),
    sales_without_returns AS (
        SELECT ss_store_sk
        FROM (
            SELECT DISTINCT s.s_store_sk AS ss_store_sk
            FROM store_sales ss
            JOIN store s ON ss.ss_store_sk = s.s_store_sk
        )
        EXCEPT
        SELECT DISTINCT sr.sr_store_sk
        FROM store_returns sr
    )
SELECT
    COALESCE(s_state, 'ALL_STATES') AS state,
    COALESCE(p_promo_name, 'ALL_PROMOS') AS promo_name,
    COALESCE(r_reason_desc, 'ALL_REASONS') AS reason_desc,
    SUM(ss_net_paid) AS total_net_paid,
    SUM(ss_net_profit) AS total_net_profit,
    SUM(sr_return_amt) AS total_return_amt,
    SUM(sr_net_loss) AS total_net_loss,
    SUM(wr_return_amt) AS total_web_return_amt,
    COUNT(*) AS txn_count,
    RANK() OVER (ORDER BY SUM(ss_net_profit) DESC) AS profit_rank
FROM base_data bd
JOIN sales_without_returns swr
    ON bd.s_store_sk = swr.ss_store_sk
GROUP BY ROLLUP(s_state, p_promo_name, r_reason_desc)
ORDER BY profit_rank
LIMIT 100
