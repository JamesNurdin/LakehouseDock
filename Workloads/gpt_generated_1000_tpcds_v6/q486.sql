WITH filtered_sales AS (
    SELECT
        ss.ss_store_sk,
        ss.ss_promo_sk,
        ss.ss_net_profit,
        ss.ss_quantity,
        s.s_store_name,
        s.s_street_name,
        s.s_street_type,
        p.p_promo_id,
        p.p_channel_email,
        t.t_am_pm,
        c.c_email_address
    FROM store_sales ss
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    WHERE regexp_like(c.c_email_address, '^.*@example\\.com$')
      AND s.s_street_name LIKE '%Park%'
      AND regexp_like(p.p_promo_id, '^AAAAAAA[AB]')
      AND t.t_am_pm = 'PM'
)
SELECT
    fs.s_store_name,
    fs.p_promo_id,
    CONCAT(fs.s_store_name, ' - ', fs.p_promo_id) AS store_promo_label,
    SUM(fs.ss_net_profit) AS total_net_profit,
    SUM(fs.ss_quantity) AS total_quantity,
    MAX(fs.t_am_pm) AS am_pm,
    (
        SELECT MAX(p2.p_cost)
        FROM promotion p2
        WHERE p2.p_promo_sk = fs.ss_promo_sk
    ) AS max_promo_cost
FROM filtered_sales fs
GROUP BY
    fs.s_store_name,
    fs.p_promo_id,
    fs.t_am_pm,
    fs.ss_promo_sk
HAVING SUM(fs.ss_net_profit) > 0
ORDER BY total_net_profit DESC
LIMIT 100
