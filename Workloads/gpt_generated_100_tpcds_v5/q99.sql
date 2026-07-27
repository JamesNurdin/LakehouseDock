WITH cs_base AS (
    SELECT
        cs.cs_order_number,
        cs.cs_bill_cdemo_sk,
        cs.cs_bill_hdemo_sk,
        cs.cs_ship_cdemo_sk,
        cs.cs_ship_hdemo_sk,
        cs.cs_net_paid,
        cs.cs_quantity
    FROM catalog_sales cs
    WHERE cs.cs_quantity > 0
)
SELECT
    csb.cs_order_number,
    cd_bill.cd_gender AS bill_gender,
    hd_bill.hd_vehicle_count AS bill_vehicle_cnt,
    ib.ib_lower_bound,
    r_sr.r_reason_desc AS store_return_reason,
    CASE WHEN sr.sr_net_loss > 0 THEN 'Loss' ELSE 'Profit' END AS loss_indicator,
    COALESCE(wr.wr_net_loss, 0) AS web_return_net_loss,
    (csb.cs_net_paid - COALESCE(sr.sr_net_loss, 0) - COALESCE(wr.wr_net_loss, 0)) AS net_after_returns,
    (
        SELECT AVG(cs2.cs_net_paid)
        FROM catalog_sales cs2
        WHERE cs2.cs_bill_cdemo_sk = cd_bill.cd_demo_sk
    ) AS avg_bill_demo_net_paid
FROM cs_base csb
JOIN customer_demographics cd_bill
    ON csb.cs_bill_cdemo_sk = cd_bill.cd_demo_sk
JOIN household_demographics hd_bill
    ON csb.cs_bill_hdemo_sk = hd_bill.hd_demo_sk
JOIN customer_demographics cd_ship
    ON csb.cs_ship_cdemo_sk = cd_ship.cd_demo_sk
JOIN household_demographics hd_ship
    ON csb.cs_ship_hdemo_sk = hd_ship.hd_demo_sk
JOIN store_returns sr
    ON sr.sr_cdemo_sk = cd_bill.cd_demo_sk
JOIN household_demographics hd_sr
    ON sr.sr_hdemo_sk = hd_sr.hd_demo_sk
JOIN reason r_sr
    ON sr.sr_reason_sk = r_sr.r_reason_sk
JOIN income_band ib
    ON hd_bill.hd_income_band_sk = ib.ib_income_band_sk
LEFT JOIN web_returns wr
    ON wr.wr_returning_cdemo_sk = cd_ship.cd_demo_sk
LEFT JOIN reason r_wr
    ON wr.wr_reason_sk = r_wr.r_reason_sk
WHERE EXISTS (
    SELECT 1
    FROM store_returns sr2
    WHERE sr2.sr_cdemo_sk = cd_bill.cd_demo_sk
      AND sr2.sr_net_loss > 100
)
ORDER BY net_after_returns DESC
LIMIT 100
