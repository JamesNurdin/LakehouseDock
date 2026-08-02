WITH ss_agg AS (
    SELECT
        ss_item_sk,
        ss_hdemo_sk,
        ss_promo_sk,
        SUM(ss_quantity) AS total_quantity,
        SUM(ss_net_paid) AS total_net_paid,
        AVG(ss_ext_tax) AS avg_ext_tax,
        COUNT(*) AS sales_cnt
    FROM store_sales
    WHERE ss_ext_tax > 20.00
      AND ss_quantity > 0
    GROUP BY ss_item_sk, ss_hdemo_sk, ss_promo_sk
),
wr_agg AS (
    SELECT
        wr_item_sk,
        wr_refunded_hdemo_sk,
        SUM(wr_return_amt) AS total_return_amt,
        SUM(wr_net_loss) AS total_net_loss,
        COUNT(*) AS returns_cnt
    FROM web_returns
    WHERE wr_return_amt < 200.00
      AND wr_return_quantity > 0
    GROUP BY wr_item_sk, wr_refunded_hdemo_sk
)
SELECT
    hd.hd_buy_potential,
    promo.p_channel_email,
    SUM(ss_agg.total_quantity) AS sum_quantity,
    SUM(ss_agg.total_net_paid) AS sum_net_paid,
    SUM(wr_agg.total_return_amt) AS sum_return_amt,
    SUM(wr_agg.total_net_loss) AS sum_net_loss,
    COUNT(DISTINCT ss_agg.ss_item_sk) AS distinct_items,
    COUNT(*) AS total_rows
FROM ss_agg
JOIN household_demographics hd
    ON ss_agg.ss_hdemo_sk = hd.hd_demo_sk
JOIN promotion promo
    ON ss_agg.ss_promo_sk = promo.p_promo_sk
LEFT JOIN wr_agg
    ON wr_agg.wr_item_sk = ss_agg.ss_item_sk
LEFT JOIN household_demographics hd_ret
    ON wr_agg.wr_refunded_hdemo_sk = hd_ret.hd_demo_sk
WHERE promo.p_discount_active = 'N'
  AND promo.p_cost >= 500
  AND promo.p_channel_email = 'N'
  AND hd.hd_vehicle_count >= 2
  AND ss_agg.total_quantity > 5
  AND (wr_agg.total_return_amt < 500 OR wr_agg.total_return_amt IS NULL)
  AND NOT EXISTS (
        SELECT 1
        FROM web_returns wr_ex
        WHERE wr_ex.wr_item_sk = ss_agg.ss_item_sk
    )
  AND hd.hd_demo_sk IN (
        SELECT ss_hdemo_sk
        FROM store_sales
        WHERE ss_quantity > 10
    )
GROUP BY GROUPING SETS (
    (hd.hd_buy_potential),
    (promo.p_channel_email),
    (hd.hd_buy_potential, promo.p_channel_email),
    ()
)
ORDER BY sum_quantity DESC
LIMIT 100
