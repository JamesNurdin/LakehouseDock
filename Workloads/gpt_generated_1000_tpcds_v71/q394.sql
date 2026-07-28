WITH filtered_customers AS (
    SELECT
        c_customer_sk,
        c_customer_id,
        c_email_address,
        regexp_extract(c_email_address, '@(.+)$', 1) AS email_domain,
        regexp_extract(c_email_address, '^([^@]+)', 1) AS email_user,
        concat(regexp_extract(c_email_address, '^([^@]+)', 1), '-VIP') AS vip_tag,
        c_current_hdemo_sk
    FROM customer
    WHERE regexp_like(c_email_address, '\\.org$')
),
joined AS (
    SELECT
        f.c_customer_id,
        f.vip_tag,
        d.d_year,
        wr.wr_return_amt,
        hd.hd_income_band_sk,
        p.p_promo_name,
        wp.wp_type,
        wp.wp_url
    FROM web_returns wr
    JOIN filtered_customers f
        ON wr.wr_refunded_customer_sk = f.c_customer_sk
    JOIN date_dim d
        ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN household_demographics hd
        ON f.c_current_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN web_page wp
        ON wr.wr_web_page_sk = wp.wp_web_page_sk
    LEFT JOIN promotion p
        ON d.d_date_sk = p.p_start_date_sk
    WHERE wp.wp_type LIKE 'ad%'
      AND regexp_like(wp.wp_url, 'promo')
)
SELECT
    d_year,
    hd_income_band_sk,
    COUNT(DISTINCT c_customer_id) AS distinct_customers,
    SUM(wr_return_amt) AS total_return_amount,
    AVG(wr_return_amt) AS avg_return_amount,
    GROUPING(d_year) AS grp_year,
    GROUPING(hd_income_band_sk) AS grp_income_band,
    ROW_NUMBER() OVER (ORDER BY SUM(wr_return_amt) DESC) AS rn
FROM joined
GROUP BY ROLLUP (d_year, hd_income_band_sk)
ORDER BY total_return_amount DESC
LIMIT 100
