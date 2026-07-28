WITH filtered_sales AS (
    SELECT
        ss.ss_ticket_number,
        ss.ss_item_sk,
        ss.ss_store_sk,
        ss.ss_promo_sk,
        ss.ss_net_profit,
        ss.ss_net_paid,
        st.s_store_id,
        st.s_city,
        st.s_state,
        substring(st.s_state FROM 1 FOR 3) AS state_prefix,
        pr.p_promo_id,
        pr.p_channel_details
    FROM store_sales ss
    JOIN store st
      ON ss.ss_store_sk = st.s_store_sk
    JOIN promotion pr
      ON ss.ss_promo_sk = pr.p_promo_sk
    WHERE regexp_like(pr.p_channel_details, '(?i)national')
      AND st.s_city LIKE '%town%'
),
joined_data AS (
    SELECT
        fs.s_store_id,
        fs.s_city,
        fs.s_state,
        fs.state_prefix,
        fs.p_promo_id,
        fs.ss_net_profit,
        fs.ss_net_paid,
        COALESCE(sr.sr_return_amt_inc_tax, 0) AS return_amt
    FROM filtered_sales fs
    LEFT JOIN store_returns sr
      ON sr.sr_ticket_number = fs.ss_ticket_number
     AND sr.sr_store_sk     = fs.ss_store_sk
     AND sr.sr_item_sk      = fs.ss_item_sk
),
agg AS (
    SELECT
        s_store_id,
        s_city,
        s_state,
        state_prefix,
        p_promo_id,
        SUM(ss_net_profit) AS total_profit,
        SUM(ss_net_paid)   AS total_sales,
        SUM(return_amt)    AS total_returns
    FROM joined_data
    GROUP BY s_store_id, s_city, s_state, state_prefix, p_promo_id
)
SELECT
    a.s_store_id,
    a.s_city,
    a.s_state,
    a.state_prefix,
    a.p_promo_id,
    concat(a.s_store_id, '-', a.p_promo_id) AS store_promo_key,
    CASE
        WHEN a.total_profit > 10000 THEN 'High'
        WHEN a.total_profit BETWEEN 0 AND 10000 THEN 'Medium'
        ELSE 'Low'
    END AS profit_category,
    a.total_sales,
    a.total_returns,
    a.total_profit,
    (
        SELECT AVG(t.total_profit)
        FROM (
            SELECT SUM(ss_net_profit) AS total_profit
            FROM store_sales
            GROUP BY ss_store_sk
        ) t
    ) AS overall_avg_profit,
    AVG(a.total_profit) OVER (PARTITION BY a.s_state) AS state_avg_profit,
    RANK() OVER (ORDER BY a.total_profit DESC) AS profit_rank
FROM agg a
ORDER BY a.total_profit DESC
LIMIT 100
