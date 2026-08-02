WITH sales_agg AS (
    SELECT
        s.s_store_id,
        s.s_store_name,
        s.s_state,
        ss.ss_sold_date_sk,
        SUM(ss.ss_net_profit) AS total_net_profit,
        COUNT(DISTINCT ss.ss_ticket_number) AS total_transactions
    FROM store_sales ss
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    WHERE p.p_purpose = 'Unknown'
      AND p.p_channel_dmail = 'Y'
    GROUP BY s.s_store_id, s.s_store_name, s.s_state, ss.ss_sold_date_sk
),
returns_agg AS (
    SELECT
        s.s_store_id,
        SUM(sr.sr_net_loss) AS total_net_loss,
        COUNT(*) AS total_returns
    FROM store_returns sr
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    GROUP BY s.s_store_id
),
profitable_stores AS (
    SELECT s_store_id
    FROM sales_agg
    WHERE total_net_profit > 20000
),
stores_with_returns AS (
    SELECT s_store_id
    FROM returns_agg
    WHERE total_returns > 0
),
target_stores AS (
    SELECT s_store_id
    FROM profitable_stores
    EXCEPT
    SELECT s_store_id
    FROM stores_with_returns
)
SELECT
    t.s_store_id AS store_id,
    sa.s_store_name AS store_name,
    sa.s_state AS state,
    sa.total_net_profit,
    ROW_NUMBER() OVER (ORDER BY sa.total_net_profit DESC) AS profit_rank
FROM target_stores t
JOIN sales_agg sa ON t.s_store_id = sa.s_store_id
WHERE sa.ss_sold_date_sk = (
    SELECT MAX(sa2.ss_sold_date_sk)
    FROM sales_agg sa2
    WHERE sa2.s_store_id = t.s_store_id
)
ORDER BY sa.total_net_profit DESC
LIMIT 100
