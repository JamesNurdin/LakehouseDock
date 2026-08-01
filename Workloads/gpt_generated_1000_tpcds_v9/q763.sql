WITH store_sales_agg AS (
    SELECT
        s.s_store_id,
        s.s_state,
        SUM(ss.ss_net_profit) AS total_net_profit
    FROM store s
    JOIN store_sales ss ON ss.ss_store_sk = s.s_store_sk
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
    GROUP BY s.s_store_id, s.s_state
    HAVING SUM(ss.ss_net_profit) > 100000
),
store_profit AS (
    SELECT
        a.s_store_id,
        a.s_state,
        a.total_net_profit,
        ROW_NUMBER() OVER (PARTITION BY a.s_state ORDER BY a.total_net_profit DESC) AS state_store_rank,
        (SELECT MAX(d2.d_year) FROM date_dim d2) AS max_year
    FROM store_sales_agg a
),
promo_sales_agg AS (
    SELECT
        s.s_store_id,
        s.s_state,
        SUM(ss.ss_net_profit) AS total_promo_profit
    FROM store s
    JOIN store_sales ss ON ss.ss_store_sk = s.s_store_sk
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    WHERE d.d_year = 2001
      AND p.p_discount_active = 'Y'
    GROUP BY s.s_store_id, s.s_state
    HAVING SUM(ss.ss_net_profit) > 150000
),
promo_store_profit AS (
    SELECT
        a.s_store_id,
        a.s_state,
        a.total_promo_profit,
        ROW_NUMBER() OVER (PARTITION BY a.s_state ORDER BY a.total_promo_profit DESC) AS promo_state_store_rank,
        (SELECT MAX(d2.d_year) FROM date_dim d2) AS max_year
    FROM promo_sales_agg a
),
intersected AS (
    SELECT
        sp.s_store_id,
        sp.s_state,
        sp.total_net_profit,
        sp.state_store_rank
    FROM store_profit sp
    INTERSECT
    SELECT
        psp.s_store_id,
        psp.s_state,
        psp.total_promo_profit AS total_net_profit,
        psp.promo_state_store_rank AS state_store_rank
    FROM promo_store_profit psp
)
SELECT
    i.s_store_id,
    i.s_state,
    i.total_net_profit,
    i.state_store_rank
FROM intersected i
ORDER BY i.total_net_profit DESC
