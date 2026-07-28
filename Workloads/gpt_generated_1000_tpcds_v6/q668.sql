WITH promo_filtered AS (
    SELECT
        p.p_promo_sk,
        p.p_promo_name,
        p.p_channel_email
    FROM promotion p
    WHERE regexp_like(p.p_promo_name, '(?i)holiday')
      AND p.p_channel_email = 'Y'
),
store_sales_agg AS (
    SELECT
        ss.ss_promo_sk,
        s.s_store_sk,
        s.s_store_name,
        s.s_city,
        SUM(ss.ss_net_paid_inc_tax) AS store_net_paid,
        SUM(ss.ss_net_profit) AS store_net_profit
    FROM store_sales ss
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN promo_filtered pf ON ss.ss_promo_sk = pf.p_promo_sk
    WHERE ss.ss_net_paid_inc_tax > 0
      AND s.s_city LIKE '%York%'
      AND substring(s.s_state FROM 1 FOR 2) = 'NY'
    GROUP BY ss.ss_promo_sk, s.s_store_sk, s.s_store_name, s.s_city
),
web_sales_agg AS (
    SELECT
        ws.ws_promo_sk,
        SUM(ws.ws_net_paid_inc_tax) AS web_net_paid,
        SUM(ws.ws_net_profit) AS web_net_profit
    FROM web_sales ws
    JOIN promo_filtered pf ON ws.ws_promo_sk = pf.p_promo_sk
    WHERE ws.ws_net_paid_inc_tax > 0
      AND regexp_like(CAST(ws.ws_coupon_amt AS varchar), '^[0-9]+\\.[0-9]{2}$')
    GROUP BY ws.ws_promo_sk
),
combined AS (
    SELECT
        pf.p_promo_sk,
        pf.p_promo_name,
        ssag.s_store_name,
        ssag.s_city,
        ssag.store_net_paid,
        ssag.store_net_profit,
        wsag.web_net_paid,
        wsag.web_net_profit,
        (ssag.store_net_paid + COALESCE(wsag.web_net_paid, 0)) AS total_net_paid,
        (ssag.store_net_profit + COALESCE(wsag.web_net_profit, 0)) AS total_net_profit,
        concat(ssag.s_store_name, ' - ', ssag.s_city) AS store_full_name
    FROM promo_filtered pf
    LEFT JOIN store_sales_agg ssag ON pf.p_promo_sk = ssag.ss_promo_sk
    LEFT JOIN web_sales_agg wsag ON pf.p_promo_sk = wsag.ws_promo_sk
)
SELECT DISTINCT
    c.p_promo_name,
    c.store_full_name,
    c.total_net_paid,
    c.total_net_profit,
    RANK() OVER (PARTITION BY c.p_promo_name ORDER BY c.total_net_profit DESC) AS profit_rank
FROM combined c
WHERE c.s_store_name IS NOT NULL
ORDER BY c.p_promo_name, profit_rank
