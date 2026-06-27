WITH channel_aggregates AS (
    -- Store channel
    SELECT
        ss.ss_promo_sk AS promo_sk,
        hd.hd_income_band_sk AS income_band_sk,
        SUM(ss.ss_net_profit) AS sales_profit,
        SUM(COALESCE(sr.sr_net_loss, 0)) AS returns_loss
    FROM store_sales ss
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN store_returns sr
        ON sr.sr_ticket_number = ss.ss_ticket_number
        AND sr.sr_item_sk = ss.ss_item_sk
    GROUP BY ss.ss_promo_sk, hd.hd_income_band_sk

    UNION ALL

    -- Catalog channel
    SELECT
        cs.cs_promo_sk AS promo_sk,
        hd.hd_income_band_sk AS income_band_sk,
        SUM(cs.cs_net_profit) AS sales_profit,
        SUM(COALESCE(cr.cr_net_loss, 0)) AS returns_loss
    FROM catalog_sales cs
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN catalog_returns cr
        ON cr.cr_order_number = cs.cs_order_number
        AND cr.cr_item_sk = cs.cs_item_sk
    GROUP BY cs.cs_promo_sk, hd.hd_income_band_sk

    UNION ALL

    -- Web channel
    SELECT
        ws.ws_promo_sk AS promo_sk,
        hd.hd_income_band_sk AS income_band_sk,
        SUM(ws.ws_net_profit) AS sales_profit,
        SUM(COALESCE(wr.wr_net_loss, 0)) AS returns_loss
    FROM web_sales ws
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    JOIN household_demographics hd ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN web_returns wr
        ON wr.wr_order_number = ws.ws_order_number
        AND wr.wr_item_sk = ws.ws_item_sk
    GROUP BY ws.ws_promo_sk, hd.hd_income_band_sk
)

SELECT
    p.p_promo_id,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    SUM(ca.sales_profit) - SUM(ca.returns_loss) AS net_profit
FROM channel_aggregates ca
JOIN promotion p ON ca.promo_sk = p.p_promo_sk
JOIN income_band ib ON ca.income_band_sk = ib.ib_income_band_sk
GROUP BY p.p_promo_id, ib.ib_lower_bound, ib.ib_upper_bound
ORDER BY net_profit DESC
LIMIT 10
