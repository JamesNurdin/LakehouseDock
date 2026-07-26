WITH hourly_sales AS (
    SELECT
        td.t_hour,
        ca.ca_state,
        p.p_promo_sk,
        p.p_promo_name,
        p.p_channel_email,
        p.p_channel_tv,
        p.p_channel_radio,
        p.p_channel_dmail,
        p.p_channel_catalog,
        p.p_channel_press,
        p.p_channel_event,
        p.p_channel_demo,
        SUM(ss.ss_net_paid) AS net_paid
    FROM store_sales ss
    JOIN time_dim td
        ON ss.ss_sold_time_sk = td.t_time_sk
    JOIN promotion p
        ON ss.ss_promo_sk = p.p_promo_sk
    JOIN customer_address ca
        ON ss.ss_addr_sk = ca.ca_address_sk
    GROUP BY td.t_hour, ca.ca_state, p.p_promo_sk, p.p_promo_name,
             p.p_channel_email, p.p_channel_tv, p.p_channel_radio,
             p.p_channel_dmail, p.p_channel_catalog, p.p_channel_press,
             p.p_channel_event, p.p_channel_demo
)
SELECT
    t_hour,
    ca_state,
    CASE
        WHEN p_channel_email = 'Y' THEN 'Email'
        WHEN p_channel_tv = 'Y' THEN 'TV'
        WHEN p_channel_radio = 'Y' THEN 'Radio'
        WHEN p_channel_dmail = 'Y' THEN 'DirectMail'
        WHEN p_channel_catalog = 'Y' THEN 'Catalog'
        WHEN p_channel_press = 'Y' THEN 'Press'
        WHEN p_channel_event = 'Y' THEN 'Event'
        WHEN p_channel_demo = 'Y' THEN 'Demo'
        ELSE 'Other'
    END AS primary_channel,
    p_promo_name,
    net_paid,
    ROW_NUMBER() OVER (PARTITION BY t_hour ORDER BY net_paid DESC) AS channel_rank,
    SUM(net_paid) OVER (PARTITION BY t_hour ORDER BY net_paid DESC ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_net_paid
FROM hourly_sales
ORDER BY t_hour, channel_rank
