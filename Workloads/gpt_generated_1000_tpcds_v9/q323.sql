WITH base AS (
    SELECT
        i.i_item_sk,
        i.i_item_id,
        i.i_category,
        hd_ws.hd_demo_sk AS ws_demo_sk,
        hd_ws.hd_income_band_sk AS ws_income_band_sk,
        hd_cs.hd_demo_sk AS cs_demo_sk,
        hd_cs.hd_income_band_sk AS cs_income_band_sk,
        p.p_promo_id,
        CASE WHEN p.p_channel_tv = 'Y' THEN 'TV' ELSE 'Other' END AS promo_channel,
        SUM(cs.cs_net_profit) AS cs_total_profit,
        SUM(ws.ws_net_profit) AS ws_total_profit,
        SUM(wr.wr_net_loss) AS total_return_loss,
        (SELECT AVG(cs_sub.cs_ext_discount_amt) FROM catalog_sales cs_sub WHERE cs_sub.cs_item_sk = i.i_item_sk) AS avg_item_discount
    FROM web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN household_demographics hd_ws ON ws.ws_bill_hdemo_sk = hd_ws.hd_demo_sk
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    JOIN catalog_sales cs ON cs.cs_item_sk = i.i_item_sk
    JOIN household_demographics hd_cs ON cs.cs_bill_hdemo_sk = hd_cs.hd_demo_sk
    JOIN web_returns wr ON wr.wr_order_number = ws.ws_order_number AND wr.wr_item_sk = ws.ws_item_sk
    JOIN household_demographics hd_wr ON wr.wr_refunded_hdemo_sk = hd_wr.hd_demo_sk
    WHERE p.p_channel_tv = 'Y'
      AND hd_ws.hd_income_band_sk >= 5
      AND i.i_category = 'Electronics'
    GROUP BY i.i_item_sk,
        i.i_item_id,
        i.i_category,
        hd_ws.hd_demo_sk,
        hd_ws.hd_income_band_sk,
        hd_cs.hd_demo_sk,
        hd_cs.hd_income_band_sk,
        p.p_promo_id,
        CASE WHEN p.p_channel_tv = 'Y' THEN 'TV' ELSE 'Other' END
)
SELECT
    b.i_item_id,
    b.i_category,
    b.ws_demo_sk,
    b.cs_demo_sk,
    b.p_promo_id,
    b.promo_channel,
    b.cs_total_profit,
    b.ws_total_profit,
    b.total_return_loss,
    (b.cs_total_profit + b.ws_total_profit - b.total_return_loss) AS net_total_profit,
    b.avg_item_discount,
    DENSE_RANK() OVER (ORDER BY (b.cs_total_profit + b.ws_total_profit - b.total_return_loss) DESC) AS profit_rank
FROM base b
WHERE EXISTS (
    SELECT 1 FROM promotion p2 WHERE p2.p_item_sk = b.i_item_sk AND p2.p_discount_active = 'Y'
)
ORDER BY profit_rank
LIMIT 100
