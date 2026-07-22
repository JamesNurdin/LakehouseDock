WITH base_sales AS (
    SELECT
        ws.ws_order_number,
        ws.ws_sold_date_sk,
        ws.ws_bill_customer_sk,
        ws.ws_bill_cdemo_sk,
        ws.ws_bill_hdemo_sk,
        ws.ws_promo_sk,
        ws.ws_item_sk,
        ws.ws_quantity,
        ws.ws_net_paid,
        ws.ws_ext_discount_amt,
        ws.ws_net_profit
    FROM web_sales ws
    WHERE ws.ws_quantity > 1
)
SELECT
    d.d_date_sk AS date_key,
    d.d_year,
    c.c_birth_country,
    cd.cd_gender,
    hd.hd_income_band_sk,
    p.p_promo_name,
    cp.cp_type,
    COUNT(DISTINCT base.ws_order_number) AS order_count,
    SUM(base.ws_net_paid) AS total_net_paid,
    AVG(base.ws_ext_discount_amt) AS avg_discount_amount,
    MIN(base.ws_net_profit) AS min_net_profit,
    MAX(base.ws_net_profit) AS max_net_profit,
    (
        SELECT COALESCE(SUM(wr2.wr_return_amt), 0)
        FROM web_returns wr2
        WHERE wr2.wr_returned_date_sk = d.d_date_sk
    ) AS total_return_amount_for_date
FROM base_sales base
JOIN date_dim d
    ON base.ws_sold_date_sk = d.d_date_sk
JOIN customer c
    ON base.ws_bill_customer_sk = c.c_customer_sk
JOIN customer_demographics cd
    ON base.ws_bill_cdemo_sk = cd.cd_demo_sk
JOIN household_demographics hd
    ON base.ws_bill_hdemo_sk = hd.hd_demo_sk
JOIN promotion p
    ON base.ws_promo_sk = p.p_promo_sk
JOIN web_returns wr
    ON base.ws_order_number = wr.wr_order_number
JOIN catalog_page cp
    ON cp.cp_start_date_sk = d.d_date_sk
WHERE
    d.d_year = 2001
    AND d.d_month_seq = 6
    AND c.c_birth_country = 'KOREA'
    AND c.c_salutation = 'Mr.'
    AND cd.cd_gender = 'M'
    AND hd.hd_income_band_sk = 10
    AND p.p_discount_active = 'Y'
    AND wr.wr_return_amt > 10
GROUP BY
    d.d_date_sk,
    d.d_year,
    c.c_birth_country,
    cd.cd_gender,
    hd.hd_income_band_sk,
    p.p_promo_name,
    cp.cp_type
ORDER BY total_net_paid DESC
LIMIT 100
