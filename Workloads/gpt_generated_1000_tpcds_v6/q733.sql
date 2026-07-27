WITH income_ranges AS (
    SELECT
        ib_income_band_sk,
        CAST(ib_lower_bound AS varchar) || '-' || CAST(ib_upper_bound AS varchar) AS income_range
    FROM income_band
)
SELECT DISTINCT
    u.return_date_sk,
    u.return_amount_inc_tax,
    u.net_loss,
    u.reason_desc,
    u.income_range,
    u.buy_potential
FROM (
    SELECT
        cr.cr_returned_date_sk AS return_date_sk,
        cr.cr_return_amt_inc_tax AS return_amount_inc_tax,
        cr.cr_net_loss AS net_loss,
        r.r_reason_desc AS reason_desc,
        ir.income_range,
        hd.hd_buy_potential AS buy_potential
    FROM catalog_returns cr
    JOIN catalog_sales cs
        ON cr.cr_order_number = cs.cs_order_number
        AND cr.cr_item_sk = cs.cs_item_sk
    JOIN household_demographics hd
        ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
    JOIN reason r
        ON cr.cr_reason_sk = r.r_reason_sk
    JOIN income_ranges ir
        ON hd.hd_income_band_sk = ir.ib_income_band_sk
    WHERE cr.cr_net_loss > (
        SELECT AVG(cr2.cr_net_loss)
        FROM catalog_returns cr2
        WHERE cr2.cr_reason_sk = cr.cr_reason_sk
    )
      AND cr.cr_return_amt_inc_tax > 1000
    UNION ALL
    SELECT
        sr.sr_returned_date_sk AS return_date_sk,
        sr.sr_return_amt_inc_tax AS return_amount_inc_tax,
        sr.sr_net_loss AS net_loss,
        r.r_reason_desc AS reason_desc,
        ir.income_range,
        hd.hd_buy_potential AS buy_potential
    FROM store_returns sr
    JOIN household_demographics hd
        ON sr.sr_hdemo_sk = hd.hd_demo_sk
    JOIN reason r
        ON sr.sr_reason_sk = r.r_reason_sk
    JOIN income_ranges ir
        ON hd.hd_income_band_sk = ir.ib_income_band_sk
    WHERE sr.sr_net_loss > (
        SELECT AVG(sr2.sr_net_loss)
        FROM store_returns sr2
        WHERE sr2.sr_reason_sk = sr.sr_reason_sk
    )
      AND sr.sr_return_amt_inc_tax > 1000
) u
ORDER BY u.return_amount_inc_tax DESC
LIMIT 100
