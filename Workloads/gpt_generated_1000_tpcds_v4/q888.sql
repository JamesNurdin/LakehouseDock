WITH joined AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        sm.sm_ship_mode_id,
        cd.cd_gender,
        cr.cr_return_tax,
        cr.cr_return_amount,
        cr.cr_net_loss AS cr_net_loss,
        sr.sr_net_loss AS sr_net_loss,
        cr.cr_ship_mode_sk
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN time_dim t ON cr.cr_returned_time_sk = t.t_time_sk
    JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN customer_demographics cd ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
    JOIN store_returns sr
        ON sr.sr_returned_date_sk = d.d_date_sk
        AND sr.sr_return_time_sk = t.t_time_sk
        AND sr.sr_cdemo_sk = cd.cd_demo_sk
        AND sr.sr_hdemo_sk = hd.hd_demo_sk
    WHERE d.d_year = 2001                      -- filter 1
      AND t.t_hour BETWEEN 8 AND 17           -- filter 2
      AND cd.cd_gender = 'M'                  -- filter 3
      AND hd.hd_income_band_sk IN (3,4,5)     -- filter 4
      AND sm.sm_carrier = 'UPS'               -- filter 5
      AND cr.cr_return_amount > 50            -- filter 6
      AND sr.sr_return_amt > 30               -- filter 7
)
SELECT
    d_year,
    d_month_seq,
    sm_ship_mode_id,
    cd_gender,
    CASE WHEN cr_return_tax > 100 THEN 'HighTax' ELSE 'LowTax' END AS tax_category,
    SUM(cr_net_loss) AS catalog_net_loss,
    SUM(sr_net_loss) AS store_net_loss,
    SUM(cr_net_loss) + SUM(sr_net_loss) AS total_net_loss,
    AVG(cr_return_amount) AS avg_return_amount,
    (SELECT AVG(cr3.cr_return_amount)
       FROM catalog_returns cr3
       WHERE cr3.cr_ship_mode_sk = joined.cr_ship_mode_sk) AS avg_return_amount_by_ship,
    ROW_NUMBER() OVER (PARTITION BY d_year ORDER BY SUM(cr_net_loss) + SUM(sr_net_loss) DESC) AS rn_yearly
FROM joined
GROUP BY
    d_year,
    d_month_seq,
    sm_ship_mode_id,
    cd_gender,
    cr_return_tax,
    cr_ship_mode_sk
ORDER BY
    d_year,
    total_net_loss DESC,
    rn_yearly
LIMIT 100
