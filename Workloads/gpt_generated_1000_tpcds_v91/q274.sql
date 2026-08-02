WITH store_demo_agg AS (
    SELECT
        s.s_store_id,
        cd.cd_gender,
        ib.ib_income_band_sk,
        COUNT(*) AS transaction_cnt,
        COALESCE(SUM(cr.cr_net_loss), 0) AS total_catalog_loss,
        COALESCE(SUM(sr.sr_net_loss), 0) AS total_store_return_loss,
        COALESCE(SUM(ss.ss_net_profit), 0) AS total_store_profit
    FROM store_sales ss
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    LEFT JOIN store_returns sr
        ON sr.sr_item_sk = ss.ss_item_sk
        AND sr.sr_ticket_number = ss.ss_ticket_number
    LEFT JOIN catalog_returns cr
        ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
        AND cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
        AND cr.cr_refunded_addr_sk = ca.ca_address_sk
    WHERE
        s.s_state = 'CA'
        AND ca.ca_state = 'CA'
        AND cd.cd_gender = 'M'
        AND cd.cd_purchase_estimate > 3000
        AND hd.hd_dep_count <= 2
        AND ib.ib_upper_bound >= 50000
        AND ss.ss_sold_date_sk BETWEEN 2451000 AND 2452000
    GROUP BY ROLLUP (s.s_store_id, cd.cd_gender, ib.ib_income_band_sk)
)

SELECT
    sd.s_store_id,
    SUM(sd.total_catalog_loss) AS sum_catalog_loss,
    SUM(sd.total_store_return_loss) AS sum_store_return_loss,
    SUM(sd.total_store_profit) AS sum_store_profit,
    (SUM(sd.total_catalog_loss) / NULLIF(SUM(sd.total_store_profit), 0)) AS loss_to_profit_ratio,
    ROW_NUMBER() OVER (ORDER BY SUM(sd.total_store_profit) DESC) AS row_num
FROM store_demo_agg sd
WHERE sd.cd_gender IS NOT NULL
  AND sd.ib_income_band_sk IS NOT NULL
  AND sd.s_store_id IN (
        SELECT s_store_id FROM store WHERE s_state = 'CA'
        UNION
        SELECT s_store_id FROM store WHERE s_state = 'NY'
    )
GROUP BY sd.s_store_id
HAVING SUM(sd.total_catalog_loss) > (SELECT AVG(total_catalog_loss) FROM store_demo_agg)
ORDER BY sum_store_profit DESC
LIMIT 100
