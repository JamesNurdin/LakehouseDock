WITH filtered_returns AS (
    SELECT
        sr_customer_sk,
        sr_cdemo_sk,
        sr_hdemo_sk,
        sr_reason_sk,
        sr_return_amt,
        sr_return_tax,
        sr_return_quantity,
        sr_net_loss
    FROM store_returns
    WHERE sr_return_amt > 500
      AND sr_return_tax < 50
      AND sr_return_quantity >= 1
      AND sr_net_loss > 0
),
agg_returns AS (
    SELECT
        c.c_customer_id               AS c_customer_id,
        cd.cd_gender                  AS cd_gender,
        ib.ib_income_band_sk          AS ib_income_band_sk,
        r.r_reason_desc               AS r_reason_desc,
        SUM(fr.sr_net_loss)           AS total_net_loss,
        COUNT(*)                      AS return_cnt,
        AVG(fr.sr_return_quantity)    AS avg_qty
    FROM filtered_returns fr
    JOIN customer c ON fr.sr_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN reason r ON fr.sr_reason_sk = r.r_reason_sk
    WHERE cd.cd_purchase_estimate >= 3000
      AND ib.ib_upper_bound <= 100000
      AND EXISTS (
            SELECT 1
            FROM reason r2
            WHERE r2.r_reason_desc LIKE '%color%'
              AND r2.r_reason_sk = r.r_reason_sk
        )
    GROUP BY ROLLUP (c.c_customer_id, cd.cd_gender, ib.ib_income_band_sk, r.r_reason_desc)
)
SELECT
    a.c_customer_id,
    a.cd_gender,
    a.ib_income_band_sk,
    a.r_reason_desc,
    a.total_net_loss,
    a.return_cnt,
    a.avg_qty,
    ROW_NUMBER() OVER (PARTITION BY a.ib_income_band_sk ORDER BY a.total_net_loss DESC) AS rn_income_band
FROM agg_returns a
ORDER BY a.total_net_loss DESC
LIMIT 100
