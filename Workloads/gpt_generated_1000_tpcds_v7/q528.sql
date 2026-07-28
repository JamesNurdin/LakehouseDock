WITH filtered AS (
    SELECT
        p.p_promo_id AS p_promo_id,
        p.p_promo_name AS p_promo_name,
        regexp_extract(c.c_email_address, '@(.+)$', 1) AS email_domain,
        wr.wr_net_loss AS wr_net_loss,
        d_ret.d_date AS d_date
    FROM web_returns wr
    JOIN date_dim d_ret
        ON wr.wr_returned_date_sk = d_ret.d_date_sk
    JOIN promotion p
        ON p.p_start_date_sk = d_ret.d_date_sk
    JOIN date_dim d_end
        ON p.p_end_date_sk = d_end.d_date_sk
    JOIN web_page wp
        ON wr.wr_web_page_sk = wp.wp_web_page_sk
    JOIN customer c
        ON wp.wp_customer_sk = c.c_customer_sk
    WHERE
        wp.wp_url LIKE '%promo%'
        AND regexp_like(c.c_email_address, '^.*@example\\.com$')
        AND regexp_like(p.p_promo_name, '^.*Discount.*$')
)
SELECT
    p_promo_id,
    p_promo_name,
    email_domain,
    COUNT(*) AS returns_cnt,
    SUM(wr_net_loss) AS total_net_loss,
    MIN(d_date) AS first_return_date,
    MAX(d_date) AS last_return_date,
    concat('Promo_', p_promo_id) AS promo_key
FROM filtered
GROUP BY
    p_promo_id,
    p_promo_name,
    email_domain
ORDER BY total_net_loss DESC
LIMIT 20
