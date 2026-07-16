WITH aggregated AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        s.s_store_id,
        s.s_city,
        COUNT(DISTINCT cr.cr_order_number) AS catalog_return_orders,
        SUM(cr.cr_net_loss) AS catalog_net_loss,
        COUNT(DISTINCT sr.sr_ticket_number) AS store_return_tickets,
        SUM(sr.sr_net_loss) AS store_net_loss,
        AVG(wp_create.wp_image_count) AS avg_image_count_creation,
        AVG(wp_access.wp_image_count) AS avg_image_count_access,
        MAX(wp_create.wp_max_ad_count) FILTER (WHERE wp_create.wp_type = 'homepage') AS max_homepage_ads,
        SUM(cr.cr_return_amount) + SUM(sr.sr_return_amt_inc_tax) AS total_return_amount,
        CASE
            WHEN SUM(cr.cr_net_loss) > SUM(sr.sr_net_loss) THEN 'Catalog higher loss'
            WHEN SUM(cr.cr_net_loss) < SUM(sr.sr_net_loss) THEN 'Store higher loss'
            ELSE 'Equal loss'
        END AS loss_comparison
    FROM catalog_returns cr
    JOIN date_dim d
        ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN store s
        ON s.s_closed_date_sk = d.d_date_sk
    JOIN store_returns sr
        ON sr.sr_returned_date_sk = d.d_date_sk
        AND sr.sr_store_sk = s.s_store_sk
    JOIN web_page wp_create
        ON wp_create.wp_creation_date_sk = d.d_date_sk
    JOIN web_page wp_access
        ON wp_access.wp_access_date_sk = d.d_date_sk
    WHERE d.d_year BETWEEN 2000 AND 2002
    GROUP BY d.d_year, d.d_month_seq, s.s_store_id, s.s_city
    HAVING COUNT(DISTINCT cr.cr_order_number) > 5
)
SELECT
    a.*,
    RANK() OVER (PARTITION BY a.d_year ORDER BY a.total_return_amount DESC) AS yearly_return_rank,
    ROUND(a.total_return_amount / NULLIF(a.catalog_return_orders + a.store_return_tickets, 0), 2) AS avg_return_amount_per_order
FROM aggregated a
ORDER BY a.d_year, yearly_return_rank
LIMIT 100
