WITH joined AS (
    SELECT
        r.r_reason_desc,
        cr.cr_net_loss      AS cr_net_loss,
        sr.sr_net_loss      AS sr_net_loss,
        wr.wr_net_loss      AS wr_net_loss,
        i.i_manufact_id,
        cd.cd_gender,
        hd.hd_income_band_sk,
        wp.wp_url
    FROM catalog_returns cr
    JOIN item i
        ON cr.cr_item_sk = i.i_item_sk
    JOIN reason r
        ON cr.cr_reason_sk = r.r_reason_sk
    JOIN customer c
        ON cr.cr_refunded_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd
        ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd
        ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
    JOIN store_returns sr
        ON sr.sr_item_sk = i.i_item_sk
    JOIN reason r2
        ON sr.sr_reason_sk = r2.r_reason_sk
    JOIN web_returns wr
        ON wr.wr_item_sk = i.i_item_sk
    JOIN reason r3
        ON wr.wr_reason_sk = r3.r_reason_sk
    LEFT JOIN web_page wp
        ON wr.wr_web_page_sk = wp.wp_web_page_sk
    WHERE i.i_manufact_id IN (117, 460)
      AND cd.cd_gender = 'M'
      AND hd.hd_income_band_sk = 5
      AND r.r_reason_desc LIKE '%Did not%'
),
aggregated AS (
    SELECT
        r_reason_desc,
        SUM(cr_net_loss) AS sum_cr_loss,
        SUM(sr_net_loss) AS sum_sr_loss,
        SUM(wr_net_loss) AS sum_wr_loss,
        COUNT(*)          AS row_cnt,
        (SUM(cr_net_loss) + SUM(sr_net_loss) + SUM(wr_net_loss)) / COUNT(*) AS avg_loss_per_row
    FROM joined
    GROUP BY r_reason_desc
)
SELECT
    r_reason_desc,
    sum_cr_loss,
    sum_sr_loss,
    sum_wr_loss,
    row_cnt,
    avg_loss_per_row
FROM aggregated
WHERE (sum_cr_loss + sum_sr_loss + sum_wr_loss) > (
        SELECT AVG(cr_net_loss) FROM catalog_returns
    )
ORDER BY avg_loss_per_row DESC
LIMIT 100
