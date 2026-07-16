WITH aggregated AS (
    SELECT
        s.s_store_id,
        s.s_store_name,
        d.d_year AS return_year,
        d.d_month_seq AS return_month_seq,
        d_closed.d_year AS store_closed_year,
        SUM(sr.sr_net_loss) AS total_net_loss,
        COUNT(DISTINCT sr.sr_ticket_number) AS total_returns,
        AVG(CASE WHEN hd.hd_buy_potential = 'HIGH' THEN 1 ELSE 0 END) AS high_buy_potential_ratio,
        SUM(COALESCE(wp.wp_image_count, 0)) AS total_images_created,
        AVG(hd.hd_income_band_sk) AS avg_income_band
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN household_demographics hd ON sr.sr_hdemo_sk = hd.hd_demo_sk
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    LEFT JOIN web_page wp ON wp.wp_creation_date_sk = d.d_date_sk
    LEFT JOIN date_dim d_closed ON s.s_closed_date_sk = d_closed.d_date_sk
    GROUP BY
        s.s_store_id,
        s.s_store_name,
        d.d_year,
        d.d_month_seq,
        d_closed.d_year
)
SELECT
    a.s_store_id,
    a.s_store_name,
    a.return_year,
    a.return_month_seq,
    a.store_closed_year,
    a.total_net_loss,
    a.total_returns,
    a.high_buy_potential_ratio,
    a.total_images_created,
    a.avg_income_band,
    ROW_NUMBER() OVER (PARTITION BY a.return_year ORDER BY a.total_net_loss DESC) AS store_year_rank
FROM aggregated a
ORDER BY a.return_year DESC, a.total_net_loss DESC
LIMIT 100
