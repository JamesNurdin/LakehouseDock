WITH joined_data AS (
    SELECT
        hd.hd_demo_sk,
        hd.hd_income_band_sk,
        hd.hd_buy_potential,
        cs.cs_net_profit,
        ws.ws_net_profit,
        sr.sr_net_loss,
        ws.ws_web_site_sk,
        ws.ws_promo_sk,
        cs.cs_list_price,
        ws.ws_sold_date_sk,
        cs.cs_sold_date_sk,
        -- combined profit for the transaction row
        (cs.cs_net_profit - sr.sr_net_loss + ws.ws_net_profit) AS combined_profit
    FROM catalog_sales cs
    JOIN household_demographics hd
        ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN web_sales ws
        ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    JOIN store_returns sr
        ON sr.sr_hdemo_sk = hd.hd_demo_sk
    JOIN web_site w
        ON ws.ws_web_site_sk = w.web_site_sk
    WHERE
        hd.hd_buy_potential = '1001-5000'
        AND cs.cs_list_price > 100
        AND ws.ws_promo_sk IN (649, 1121)
        AND w.web_state = 'CA'
),
agg_data AS (
    SELECT
        jd.hd_income_band_sk,
        jd.ws_web_site_sk,
        SUM(jd.combined_profit) AS total_combined_profit,
        COUNT(*) AS transaction_count,
        AVG(jd.combined_profit) AS avg_combined_profit
    FROM joined_data jd
    GROUP BY jd.hd_income_band_sk, jd.ws_web_site_sk
    HAVING SUM(jd.combined_profit) > 10000
)
SELECT
    a.hd_income_band_sk,
    a.ws_web_site_sk,
    a.total_combined_profit,
    a.transaction_count,
    a.avg_combined_profit,
    (SELECT AVG(total_combined_profit) FROM agg_data) AS overall_avg_total_profit,
    RANK() OVER (PARTITION BY a.hd_income_band_sk ORDER BY a.total_combined_profit DESC) AS profit_rank_within_income
FROM agg_data a
ORDER BY a.total_combined_profit DESC
LIMIT 100
