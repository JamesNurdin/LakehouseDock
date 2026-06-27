WITH store AS (
    SELECT
        p.p_promo_id,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        SUM(ss.ss_net_profit) AS total_net_profit,
        COALESCE(SUM(sr.sr_net_loss), 0) AS total_net_loss
    FROM store_sales ss
    JOIN promotion p
        ON ss.ss_promo_sk = p.p_promo_sk
    JOIN household_demographics hd
        ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    LEFT JOIN store_returns sr
        ON sr.sr_ticket_number = ss.ss_ticket_number
    WHERE p.p_discount_active = 'Y'
    GROUP BY p.p_promo_id, ib.ib_lower_bound, ib.ib_upper_bound
),
catalog AS (
    SELECT
        p.p_promo_id,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        SUM(cs.cs_net_profit) AS total_net_profit,
        COALESCE(SUM(cr.cr_net_loss), 0) AS total_net_loss
    FROM catalog_sales cs
    JOIN promotion p
        ON cs.cs_promo_sk = p.p_promo_sk
    JOIN household_demographics hd
        ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    LEFT JOIN catalog_returns cr
        ON cr.cr_order_number = cs.cs_order_number
    WHERE p.p_discount_active = 'Y'
    GROUP BY p.p_promo_id, ib.ib_lower_bound, ib.ib_upper_bound
),
web AS (
    SELECT
        p.p_promo_id,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        SUM(ws.ws_net_profit) AS total_net_profit,
        COALESCE(SUM(wr.wr_net_loss), 0) AS total_net_loss
    FROM web_sales ws
    JOIN promotion p
        ON ws.ws_promo_sk = p.p_promo_sk
    JOIN household_demographics hd
        ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    LEFT JOIN web_returns wr
        ON wr.wr_order_number = ws.ws_order_number
    WHERE p.p_discount_active = 'Y'
    GROUP BY p.p_promo_id, ib.ib_lower_bound, ib.ib_upper_bound
)
SELECT
    p_promo_id,
    ib_lower_bound,
    ib_upper_bound,
    SUM(total_net_profit) AS total_net_profit,
    SUM(total_net_loss) AS total_net_loss,
    SUM(total_net_profit) - SUM(total_net_loss) AS net_profit_after_returns
FROM (
    SELECT * FROM store
    UNION ALL
    SELECT * FROM catalog
    UNION ALL
    SELECT * FROM web
) combined
GROUP BY p_promo_id, ib_lower_bound, ib_upper_bound
ORDER BY net_profit_after_returns DESC
LIMIT 10
