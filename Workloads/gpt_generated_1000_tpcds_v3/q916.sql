WITH joined AS (
    SELECT
        ss.ss_store_sk,
        ib.ib_income_band_sk,
        ss.ss_quantity,
        ss.ss_net_profit,
        sr.sr_net_loss,
        cr.cr_net_loss,
        cs.cs_net_profit,
        sr.sr_ticket_number,
        cs.cs_order_number
    FROM store_sales ss
    JOIN customer_demographics cd
        ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd
        ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN customer_address ca
        ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN store_returns sr
        ON sr.sr_ticket_number = ss.ss_ticket_number
        AND sr.sr_item_sk = ss.ss_item_sk
        AND sr.sr_cdemo_sk = cd.cd_demo_sk
        AND sr.sr_hdemo_sk = hd.hd_demo_sk
        AND sr.sr_addr_sk = ca.ca_address_sk
    JOIN reason r_store
        ON sr.sr_reason_sk = r_store.r_reason_sk
    JOIN catalog_sales cs
        ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
        AND cs.cs_bill_hdemo_sk = hd.hd_demo_sk
        AND cs.cs_bill_addr_sk = ca.ca_address_sk
    JOIN catalog_returns cr
        ON cr.cr_order_number = cs.cs_order_number
        AND cr.cr_item_sk = cs.cs_item_sk
    JOIN reason r_cat
        ON cr.cr_reason_sk = r_cat.r_reason_sk
    JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE
        ss.ss_quantity > 50
        AND ca.ca_state = 'CA'
        AND ib.ib_upper_bound > 50000
        AND r_store.r_reason_desc LIKE '%price%'
),
agg AS (
    SELECT
        ss_store_sk,
        ib_income_band_sk,
        SUM(sr_net_loss) AS total_store_net_loss,
        SUM(cr_net_loss) AS total_catalog_net_loss,
        SUM(ss_net_profit) AS total_store_net_profit,
        SUM(cs_net_profit) AS total_catalog_net_profit,
        COUNT(DISTINCT sr_ticket_number) AS return_count,
        COUNT(DISTINCT cs_order_number) AS sales_count,
        AVG(ss_quantity) AS avg_quantity
    FROM joined
    GROUP BY ss_store_sk, ib_income_band_sk
)
SELECT
    ss_store_sk,
    ib_income_band_sk,
    total_store_net_loss + total_catalog_net_loss AS total_net_loss,
    total_store_net_profit + total_catalog_net_profit AS total_net_profit,
    (total_store_net_loss + total_catalog_net_loss) / NULLIF(total_store_net_profit + total_catalog_net_profit, 0) AS loss_to_profit_ratio,
    return_count,
    sales_count,
    (SELECT AVG(a.total_store_net_loss + a.total_catalog_net_loss) FROM agg a) AS overall_avg_net_loss
FROM agg
WHERE (total_store_net_loss + total_catalog_net_loss) > (
    SELECT AVG(a.total_store_net_loss + a.total_catalog_net_loss) FROM agg a
)
ORDER BY loss_to_profit_ratio DESC
LIMIT 100
