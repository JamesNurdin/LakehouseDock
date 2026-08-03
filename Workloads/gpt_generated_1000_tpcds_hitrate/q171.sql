WITH per_store AS (
    SELECT
        s.s_store_id,
        s.s_state,
        SUM(sr.sr_net_loss) AS store_net_loss,
        COUNT(*) AS store_return_cnt,
        SUM(cr.cr_net_loss) AS catalog_net_loss,
        SUM(wr.wr_net_loss) AS web_net_loss,
        SUM(CASE WHEN cp.cp_type = 'monthly' THEN cr.cr_net_loss ELSE 0 END) AS monthly_catalog_loss,
        SUM(CASE WHEN cd.cd_gender = 'F' THEN sr.sr_return_amt ELSE 0 END) AS female_return_amount
    FROM store_returns sr
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    JOIN customer_demographics cd ON sr.sr_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON sr.sr_hdemo_sk = hd.hd_demo_sk
    JOIN catalog_returns cr ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
    JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN web_returns wr ON wr.wr_refunded_cdemo_sk = cd.cd_demo_sk
    WHERE s.s_state = 'CA'
      AND cd.cd_gender = 'M'
      AND cp.cp_type = 'monthly'
      AND cr.cr_return_amount > 50
      AND wr.wr_return_quantity > 1
    GROUP BY s.s_store_id, s.s_state
)
SELECT
    t.s_store_id,
    t.s_state,
    t.store_net_loss,
    t.catalog_net_loss,
    t.web_net_loss,
    t.total_net_loss,
    t.loss_category,
    t.store_return_cnt,
    t.female_return_amount
FROM (
    SELECT
        s_store_id,
        s_state,
        store_net_loss,
        catalog_net_loss,
        web_net_loss,
        (store_net_loss + catalog_net_loss + web_net_loss) AS total_net_loss,
        CASE
            WHEN (store_net_loss + catalog_net_loss + web_net_loss) > 2000 THEN 'High'
            ELSE 'Low'
        END AS loss_category,
        store_return_cnt,
        female_return_amount
    FROM per_store
) t
WHERE t.total_net_loss > 0
ORDER BY t.total_net_loss DESC
LIMIT 100
