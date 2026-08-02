WITH base AS (
    SELECT
        p.p_promo_id,
        p.p_promo_name,
        regexp_extract(p.p_promo_name, '[0-9]+', 0) AS promo_number,
        substring(p.p_promo_name, 1, 6) AS promo_prefix,
        p.p_channel_dmail,
        p.p_channel_email,
        ws.ws_sold_date_sk,
        ws.ws_net_profit,
        ws.ws_net_paid_inc_ship,
        concat(p.p_channel_dmail, '-', p.p_channel_email) AS channel_combo,
        w.web_state,
        w.web_city
    FROM web_sales ws
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    JOIN web_site w ON ws.ws_web_site_sk = w.web_site_sk
    WHERE regexp_like(p.p_promo_name, '^PROMO[0-9]+')
),
filtered_a AS (
    SELECT
        p_promo_id,
        p_promo_name,
        promo_number,
        promo_prefix,
        p_channel_dmail,
        p_channel_email,
        ws_sold_date_sk,
        ws_net_profit,
        ws_net_paid_inc_ship,
        channel_combo,
        web_state,
        web_city
    FROM base
    WHERE p_channel_dmail = 'Y'
      AND p_channel_email = 'N'
      AND web_state = 'PA'
      AND web_city LIKE '%County'
),
filtered_b AS (
    SELECT
        p_promo_id,
        p_promo_name,
        promo_number,
        promo_prefix,
        p_channel_dmail,
        p_channel_email,
        ws_sold_date_sk,
        ws_net_profit,
        ws_net_paid_inc_ship,
        channel_combo,
        web_state,
        web_city
    FROM base
    WHERE p_channel_email = 'Y'
      AND p_channel_dmail = 'N'
      AND web_state = 'NY'
      AND web_city LIKE '%County'
),
unioned AS (
    SELECT
        p_promo_id,
        p_promo_name,
        promo_number,
        promo_prefix,
        ws_sold_date_sk,
        SUM(ws_net_profit) AS total_profit,
        SUM(ws_net_paid_inc_ship) AS total_paid_inc_ship,
        channel_combo,
        web_state
    FROM filtered_a
    GROUP BY p_promo_id, p_promo_name, promo_number, promo_prefix, ws_sold_date_sk, channel_combo, web_state
    UNION
    SELECT
        p_promo_id,
        p_promo_name,
        promo_number,
        promo_prefix,
        ws_sold_date_sk,
        SUM(ws_net_profit) AS total_profit,
        SUM(ws_net_paid_inc_ship) AS total_paid_inc_ship,
        channel_combo,
        web_state
    FROM filtered_b
    GROUP BY p_promo_id, p_promo_name, promo_number, promo_prefix, ws_sold_date_sk, channel_combo, web_state
),
final AS (
    SELECT
        u.p_promo_id,
        u.p_promo_name,
        u.promo_number,
        u.promo_prefix,
        u.ws_sold_date_sk,
        u.total_profit,
        u.total_paid_inc_ship,
        u.channel_combo,
        u.web_state,
        LAG(u.total_profit) OVER (PARTITION BY u.p_promo_id ORDER BY u.ws_sold_date_sk) AS prev_total_profit,
        SUM(u.total_profit) OVER (PARTITION BY u.p_promo_id ORDER BY u.ws_sold_date_sk ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_profit
    FROM unioned u
)
SELECT
    f.p_promo_id,
    f.p_promo_name,
    f.promo_number,
    f.promo_prefix,
    f.web_state,
    f.channel_combo,
    f.ws_sold_date_sk,
    f.total_profit,
    f.prev_total_profit,
    f.cumulative_profit,
    f.total_paid_inc_ship
FROM final f
ORDER BY f.p_promo_id, f.ws_sold_date_sk
