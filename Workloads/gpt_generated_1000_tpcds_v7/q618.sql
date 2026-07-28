WITH wr AS (
        SELECT
            wr_returned_date_sk,
            wr_return_amt,
            wr_net_loss,
            wr_refunded_cdemo_sk,
            wr_return_quantity
        FROM web_returns
        WHERE wr_return_quantity > 0
    ),
    cd AS (
        SELECT
            cd_demo_sk,
            cd_credit_rating,
            cd_education_status,
            cd_gender
        FROM customer_demographics
        WHERE regexp_like(cd_credit_rating, '^A[0-9]$')
    ),
    d_ret AS (
        SELECT
            d_date_sk,
            d_year,
            d_month_seq,
            d_moy
        FROM date_dim
    ),
    store_join AS (
        SELECT
            s.s_store_sk,
            s.s_manager,
            d.d_year,
            d.d_month_seq,
            d.d_moy
        FROM store s
        JOIN date_dim d ON s.s_closed_date_sk = d.d_date_sk
        WHERE s.s_manager LIKE '%Coleman%'
    ),
    promo AS (
        SELECT
            p.p_promo_sk,
            regexp_extract(p.p_purpose, '(\\w+)', 1) AS purpose_word,
            d.d_year,
            d.d_month_seq
        FROM promotion p
        JOIN date_dim d ON p.p_start_date_sk = d.d_date_sk
        WHERE p.p_channel_email = 'N' AND p.p_purpose IS NOT NULL
    )
SELECT
    d_ret.d_year,
    d_ret.d_moy,
    s.s_manager,
    p.purpose_word,
    SUM(wr.wr_net_loss) AS total_net_loss,
    COUNT(*) AS returns_cnt,
    ROUND(AVG(wr.wr_return_amt), 2) AS avg_return_amount
FROM wr
JOIN cd ON wr.wr_refunded_cdemo_sk = cd.cd_demo_sk
JOIN d_ret ON wr.wr_returned_date_sk = d_ret.d_date_sk
JOIN store_join s ON d_ret.d_year = s.d_year AND d_ret.d_month_seq = s.d_month_seq
JOIN promo p ON d_ret.d_year = p.d_year AND d_ret.d_month_seq = p.d_month_seq
GROUP BY d_ret.d_year, d_ret.d_moy, s.s_manager, p.purpose_word
ORDER BY total_net_loss DESC
LIMIT 100
