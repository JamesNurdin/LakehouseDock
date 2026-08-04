WITH returns AS (
    SELECT
        sm.sm_ship_mode_id,
        hd.hd_income_band_sk,
        SUM(cr.cr_net_loss) AS catalog_net_loss,
        SUM(sr.sr_net_loss) AS store_net_loss,
        SUM(cr.cr_net_loss) + SUM(sr.sr_net_loss) AS total_net_loss,
        concat(sm.sm_ship_mode_id, '-', CAST(hd.hd_income_band_sk AS varchar)) AS ship_income_key
    FROM catalog_returns cr
    JOIN customer c
        ON cr.cr_refunded_customer_sk = c.c_customer_sk
    JOIN household_demographics hd
        ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
    JOIN ship_mode sm
        ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN store_returns sr
        ON sr.sr_customer_sk = c.c_customer_sk
        AND sr.sr_hdemo_sk = hd.hd_demo_sk
    WHERE regexp_like(c.c_email_address, '^[A-Za-z][A-Za-z0-9._%+-]*@[^@]+\\.com$')
      AND sm.sm_contract LIKE '%a%'
    GROUP BY
        sm.sm_ship_mode_id,
        hd.hd_income_band_sk,
        concat(sm.sm_ship_mode_id, '-', CAST(hd.hd_income_band_sk AS varchar))
)
SELECT
    ship_mode_id,
    income_band_sk,
    ship_income_key,
    total_net_loss,
    catalog_net_loss,
    store_net_loss,
    rank
FROM (
    SELECT
        sm_ship_mode_id AS ship_mode_id,
        hd_income_band_sk AS income_band_sk,
        ship_income_key,
        total_net_loss,
        catalog_net_loss,
        store_net_loss,
        ROW_NUMBER() OVER (PARTITION BY sm_ship_mode_id ORDER BY total_net_loss DESC) AS rank
    FROM returns
) t
WHERE rank <= 3
ORDER BY ship_mode_id, rank
