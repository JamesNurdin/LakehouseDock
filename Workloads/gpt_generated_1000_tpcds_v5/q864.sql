WITH filtered_returns AS (
    SELECT
        wr.wr_refunded_customer_sk,
        wr.wr_net_loss,
        wr.wr_return_quantity,
        wp.wp_url,
        wp.wp_type,
        c.c_current_hdemo_sk AS hd_demo_sk,
        hd.hd_buy_potential,
        hd.hd_dep_count,
        -- extract numeric campaign id from the URL, e.g., '.../campaign123/...'
        regexp_extract(wp.wp_url, 'campaign([0-9]+)', 1) AS campaign_id
    FROM web_returns wr
    JOIN web_page wp
        ON wr.wr_web_page_sk = wp.wp_web_page_sk
    JOIN customer c
        ON wr.wr_refunded_customer_sk = c.c_customer_sk
    JOIN household_demographics hd
        ON c.c_current_hdemo_sk = hd.hd_demo_sk
    WHERE regexp_like(wp.wp_url, 'campaign[0-9]+')
      AND (c.c_salutation LIKE 'Mr.%' OR c.c_salutation LIKE 'Ms.%')
)
SELECT
    fr.hd_demo_sk,
    fr.hd_buy_potential,
    COUNT(DISTINCT fr.campaign_id) AS distinct_campaigns,
    SUM(fr.wr_net_loss) AS total_net_loss,
    AVG(fr.wr_net_loss) AS avg_net_loss,
    SUM(fr.wr_return_quantity) AS total_return_qty
FROM filtered_returns fr
WHERE fr.campaign_id IS NOT NULL
GROUP BY fr.hd_demo_sk, fr.hd_buy_potential
HAVING AVG(fr.wr_net_loss) > 100
ORDER BY avg_net_loss DESC
LIMIT 100
