WITH agg AS (
    SELECT 
        c.c_customer_id,
        cd.cd_gender,
        ib.ib_lower_bound,
        SUM(sr.sr_net_loss) AS total_net_loss
    FROM store_returns sr
    JOIN time_dim td ON sr.sr_return_time_sk = td.t_time_sk
    JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON sr.sr_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON sr.sr_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE 
        td.t_minute >= 12
        AND td.t_sub_shift = 'morning'
        AND hd.hd_vehicle_count >= 1
        AND ib.ib_lower_bound >= 50000
        AND sr.sr_fee > 10
        AND c.c_current_cdemo_sk = cd.cd_demo_sk
        AND c.c_current_hdemo_sk = hd.hd_demo_sk
        AND EXISTS (
            SELECT 1 FROM (
                SELECT DISTINCT wp_customer_sk
                FROM web_page
                WHERE wp_type = 'article'
                  AND wp_url LIKE '%example.com%'
            ) wp
            WHERE wp.wp_customer_sk = c.c_customer_sk
        )
    GROUP BY 
        c.c_customer_id,
        cd.cd_gender,
        ib.ib_lower_bound
    HAVING SUM(sr.sr_net_loss) > 0
)
SELECT 
    c_customer_id,
    cd_gender,
    ib_lower_bound,
    total_net_loss,
    RANK() OVER (PARTITION BY ib_lower_bound ORDER BY total_net_loss DESC) AS loss_rank,
    ROW_NUMBER() OVER (PARTITION BY cd_gender ORDER BY total_net_loss DESC) AS gender_rank,
    CASE WHEN total_net_loss > 1000 THEN 'High' ELSE 'Low' END AS loss_category
FROM agg
ORDER BY total_net_loss DESC
LIMIT 100
