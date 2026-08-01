WITH unioned_returns AS (
    SELECT
        cr_returned_date_sk,
        cr_refunded_customer_sk,
        cr_refunded_cdemo_sk,
        cr_refunded_hdemo_sk,
        cr_refunded_addr_sk,
        cr_return_quantity,
        cr_return_amount,
        cr_net_loss
    FROM catalog_returns TABLESAMPLE BERNOULLI (5)
    WHERE cr_return_amount > 500
    UNION
    SELECT
        cr_returned_date_sk,
        cr_refunded_customer_sk,
        cr_refunded_cdemo_sk,
        cr_refunded_hdemo_sk,
        cr_refunded_addr_sk,
        cr_return_quantity,
        cr_return_amount,
        cr_net_loss
    FROM catalog_returns
    WHERE cr_return_amount <= 500
)
SELECT
    d.d_year,
    c.c_customer_id,
    cd.cd_gender,
    hd.hd_buy_potential,
    ca.ca_state,
    wp_l.wp_web_page_id,
    ur.cr_return_quantity,
    ur.cr_return_amount,
    ur.cr_net_loss,
    RANK() OVER (PARTITION BY d.d_year ORDER BY ur.cr_net_loss DESC) AS loss_rank,
    CASE
        WHEN ur.cr_net_loss > 0 THEN 'LOSS'
        ELSE 'NO LOSS'
    END AS loss_flag
FROM unioned_returns ur
FULL OUTER JOIN date_dim d
    ON ur.cr_returned_date_sk = d.d_date_sk
LEFT JOIN customer c
    ON ur.cr_refunded_customer_sk = c.c_customer_sk
LEFT JOIN customer_demographics cd
    ON ur.cr_refunded_cdemo_sk = cd.cd_demo_sk
LEFT JOIN household_demographics hd
    ON ur.cr_refunded_hdemo_sk = hd.hd_demo_sk
LEFT JOIN customer_address ca
    ON ur.cr_refunded_addr_sk = ca.ca_address_sk
LEFT JOIN LATERAL (
    SELECT wp.wp_web_page_id, wp.wp_char_count
    FROM web_page wp
    WHERE wp.wp_customer_sk = c.c_customer_sk
      AND wp.wp_creation_date_sk = d.d_date_sk
    ORDER BY wp.wp_char_count DESC
    LIMIT 1
) wp_l ON true
WHERE
    d.d_year BETWEEN 1999 AND 2002
    AND ca.ca_state = 'CA'
    AND cd.cd_gender = 'M'
    AND hd.hd_income_band_sk = 3
    AND wp_l.wp_char_count > 2000
ORDER BY d.d_year, loss_rank
LIMIT 100
