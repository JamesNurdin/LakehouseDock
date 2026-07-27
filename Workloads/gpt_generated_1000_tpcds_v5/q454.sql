WITH joined_data AS (
    SELECT
        i.i_item_id,
        r.r_reason_desc,
        sr.sr_net_loss AS sr_net_loss,
        cr.cr_net_loss AS cr_net_loss,
        wr.wr_net_loss AS wr_net_loss
    FROM store_sales ss
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    LEFT JOIN store_returns sr
        ON sr.sr_ticket_number = ss.ss_ticket_number
        AND sr.sr_item_sk = ss.ss_item_sk
    LEFT JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    LEFT JOIN catalog_returns cr
        ON cr.cr_item_sk = i.i_item_sk
        AND cr.cr_reason_sk = r.r_reason_sk
    LEFT JOIN web_returns wr
        ON wr.wr_item_sk = i.i_item_sk
        AND wr.wr_reason_sk = r.r_reason_sk
    WHERE ss.ss_sold_date_sk BETWEEN 2450000 AND 2459999
      AND i.i_current_price > 20.00
      AND cd.cd_gender = 'M'
      AND ib.ib_upper_bound <= 50000
      AND sr.sr_return_quantity > 1
),
per_item_reason AS (
    SELECT
        i_item_id,
        r_reason_desc,
        SUM(COALESCE(sr_net_loss, 0) + COALESCE(cr_net_loss, 0) + COALESCE(wr_net_loss, 0)) AS total_net_loss,
        COUNT(*) AS cnt
    FROM (
        SELECT DISTINCT i_item_id, r_reason_desc, sr_net_loss, cr_net_loss, wr_net_loss
        FROM joined_data
    ) sub
    GROUP BY i_item_id, r_reason_desc
)
SELECT
    i_item_id,
    ROUND(AVG(total_net_loss), 2) AS avg_total_net_loss,
    SUM(cnt) AS total_occurrences
FROM per_item_reason
GROUP BY i_item_id
HAVING AVG(total_net_loss) > 1000
ORDER BY avg_total_net_loss DESC
LIMIT 100
