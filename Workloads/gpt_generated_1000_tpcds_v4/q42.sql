WITH joined_data AS (
    SELECT
        cs.cs_item_sk,
        cs.cs_bill_hdemo_sk AS hd_demo_sk,
        hd.hd_income_band_sk,
        i.i_manager_id,
        i.i_current_price,
        p.p_promo_sk,
        p.p_channel_tv,
        cs.cs_quantity,
        cs.cs_net_profit,
        sr.sr_net_loss,
        wr.wr_net_loss,
        CASE WHEN cs.cs_net_profit > 0 THEN 'Profit' ELSE 'Loss' END AS profit_flag
    FROM catalog_sales cs
    JOIN household_demographics hd
        ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN item i
        ON cs.cs_item_sk = i.i_item_sk
    JOIN promotion p
        ON cs.cs_promo_sk = p.p_promo_sk
    LEFT JOIN store_returns sr
        ON sr.sr_item_sk = i.i_item_sk
        AND sr.sr_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN web_returns wr
        ON wr.wr_item_sk = i.i_item_sk
        AND wr.wr_refunded_hdemo_sk = hd.hd_demo_sk
    WHERE i.i_manager_id = 41
      AND p.p_channel_tv = 'N'
      AND p.p_promo_sk IN (9, 16, 18, 20)
      AND hd.hd_vehicle_count >= 1
),
agg_by_demo AS (
    SELECT
        hd_income_band_sk,
        profit_flag,
        SUM(cs_net_profit) AS total_sales_profit,
        SUM(COALESCE(sr_net_loss, 0) + COALESCE(wr_net_loss, 0)) AS total_return_loss,
        COUNT(*) AS txn_count
    FROM joined_data
    GROUP BY hd_income_band_sk, profit_flag
)
SELECT
    agg.hd_income_band_sk,
    agg.profit_flag,
    agg.total_sales_profit,
    agg.total_return_loss,
    (agg.total_sales_profit - agg.total_return_loss) AS net_total,
    (SELECT AVG(cs2.cs_net_profit)
     FROM catalog_sales cs2
     JOIN household_demographics hd2
       ON cs2.cs_bill_hdemo_sk = hd2.hd_demo_sk
     WHERE hd2.hd_income_band_sk = agg.hd_income_band_sk) AS overall_avg_profit
FROM agg_by_demo agg
WHERE (agg.total_sales_profit - agg.total_return_loss) > 1000
  AND agg.txn_count >= 5
ORDER BY net_total DESC
LIMIT 100
