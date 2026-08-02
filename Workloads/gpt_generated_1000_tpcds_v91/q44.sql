WITH filtered_customers AS (
    SELECT
        c.c_customer_sk,
        c.c_email_address,
        c.c_salutation,
        cd.cd_gender,
        cd.cd_marital_status,
        hd.hd_demo_sk
    FROM
        customer c
        JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
        JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    WHERE
        c.c_salutation = 'Mrs.'
        AND c.c_email_address LIKE '%@aKRz.edu'
        AND cd.cd_gender = 'F'
        AND cd.cd_marital_status = 'M'
)
SELECT
    p.p_promo_id,
    d.d_year,
    cd_ret.cd_gender,
    cd_ret.cd_marital_status,
    COUNT(DISTINCT fc.c_customer_sk) AS distinct_customers,
    SUM(sr.sr_net_loss) + SUM(wr.wr_net_loss) AS total_net_loss,
    SUM(sr.sr_return_amt) + SUM(wr.wr_return_amt) AS total_return_amount,
    AVG(sr.sr_return_quantity) AS avg_store_return_qty,
    AVG(wr.wr_return_quantity) AS avg_web_return_qty,
    COUNT(*) AS total_returns
FROM
    filtered_customers fc
    JOIN store_returns sr TABLESAMPLE BERNOULLI (10) ON sr.sr_customer_sk = fc.c_customer_sk
    JOIN customer_demographics cd_ret ON sr.sr_cdemo_sk = cd_ret.cd_demo_sk
    JOIN household_demographics hd_store ON sr.sr_hdemo_sk = hd_store.hd_demo_sk
    JOIN web_returns wr ON wr.wr_refunded_customer_sk = fc.c_customer_sk
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
        AND wr.wr_returned_date_sk = d.d_date_sk
    JOIN promotion p ON p.p_start_date_sk = d.d_date_sk
WHERE
    d.d_year = 2000
    AND d.d_moy = 12
    AND d.d_current_quarter = 'Y'
    AND p.p_discount_active = 'Y'
GROUP BY
    p.p_promo_id,
    d.d_year,
    cd_ret.cd_gender,
    cd_ret.cd_marital_status
ORDER BY
    total_net_loss DESC
LIMIT 100
