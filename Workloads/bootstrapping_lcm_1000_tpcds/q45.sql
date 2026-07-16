WITH agg_data AS (
    SELECT
        dd.d_year,
        dd.d_month_seq,
        i.i_category,
        SUM(cr.cr_net_loss) AS total_net_loss,
        SUM(cr.cr_return_quantity) AS total_return_qty,
        SUM(cr.cr_return_amount) AS total_return_amount,
        AVG(cr.cr_return_amount) AS avg_return_amount,
        SUM(cr.cr_fee) AS total_fee,
        SUM(cr.cr_return_tax) AS total_return_tax,
        COUNT(DISTINCT s.s_store_sk) AS closed_store_count,
        COUNT(DISTINCT wp.wp_web_page_sk) AS web_page_count,
        MIN(i.i_current_price) AS min_price,
        MAX(i.i_current_price) AS max_price
    FROM catalog_returns cr
    JOIN date_dim dd ON cr.cr_returned_date_sk = dd.d_date_sk
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    JOIN store s ON s.s_closed_date_sk = dd.d_date_sk
    JOIN web_page wp ON wp.wp_creation_date_sk = dd.d_date_sk AND wp.wp_access_date_sk = dd.d_date_sk
    WHERE dd.d_year BETWEEN 2000 AND 2005
    GROUP BY dd.d_year, dd.d_month_seq, i.i_category
    HAVING SUM(cr.cr_net_loss) > 1000
)
SELECT
    ad.d_year,
    ad.d_month_seq,
    ad.i_category,
    ad.total_net_loss,
    ad.total_return_qty,
    ad.avg_return_amount,
    ad.total_fee,
    ad.total_return_tax,
    ad.closed_store_count,
    ad.web_page_count,
    ad.min_price,
    ad.max_price,
    CASE
        WHEN ad.total_net_loss > 10000 THEN 'HIGH'
        WHEN ad.total_net_loss > 5000 THEN 'MEDIUM'
        ELSE 'LOW'
    END AS net_loss_category,
    ad.total_net_loss / NULLIF(ad.total_return_amount, 0) AS net_loss_to_return_amount_ratio,
    ROW_NUMBER() OVER (PARTITION BY ad.d_year ORDER BY ad.total_net_loss DESC) AS rank_within_year
FROM agg_data ad
ORDER BY ad.total_net_loss DESC
LIMIT 100
