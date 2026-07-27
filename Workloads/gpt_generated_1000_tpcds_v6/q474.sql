WITH agg1 AS (
    SELECT
        ib.ib_income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        SUM(cr.cr_net_loss) AS total_cr_loss,
        SUM(sr.sr_net_loss) AS total_sr_loss,
        SUM(ws.ws_net_profit) AS total_ws_profit,
        COUNT(DISTINCT cr.cr_order_number) AS distinct_orders
    FROM household_demographics hd
    JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN catalog_returns cr
        ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
    JOIN store_returns sr
        ON sr.sr_hdemo_sk = hd.hd_demo_sk
    JOIN store s
        ON s.s_store_sk = sr.sr_store_sk
    JOIN web_sales ws
        ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    WHERE ib.ib_lower_bound >= 10000
      AND ib.ib_upper_bound <= 200000
      AND cr.cr_return_amount > 500
      AND sr.sr_return_quantity BETWEEN 10 AND 50
      AND s.s_state = 'CA'
    GROUP BY
        ib.ib_income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound
)
SELECT
    agg1.ib_income_band_sk,
    agg1.ib_lower_bound,
    agg1.ib_upper_bound,
    agg1.total_cr_loss,
    agg1.total_sr_loss,
    agg1.total_ws_profit,
    agg1.distinct_orders,
    CASE WHEN agg1.total_ws_profit > 5000 THEN 'High' ELSE 'Low' END AS profit_category,
    (
        SELECT AVG(cr2.cr_return_amount)
        FROM catalog_returns cr2
        JOIN household_demographics hd2
          ON cr2.cr_refunded_hdemo_sk = hd2.hd_demo_sk
        WHERE hd2.hd_income_band_sk = agg1.ib_income_band_sk
    ) AS avg_return_amount_by_income_band
FROM agg1
WHERE agg1.total_cr_loss > 1000
ORDER BY agg1.total_ws_profit DESC
LIMIT 100
