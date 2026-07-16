WITH returns_by_month AS (
    SELECT 
        d_ret.d_year,
        d_ret.d_month_seq,
        i.i_category,
        i.i_brand,
        SUM(cr.cr_return_amount) AS total_return_amount,
        SUM(cr.cr_net_loss) AS total_net_loss,
        COUNT(*) AS return_cnt
    FROM catalog_returns cr
    JOIN date_dim d_ret ON cr.cr_returned_date_sk = d_ret.d_date_sk
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    GROUP BY 
        d_ret.d_year,
        d_ret.d_month_seq,
        i.i_category,
        i.i_brand
),
store_closures_by_month AS (
    SELECT 
        d_store.d_year,
        d_store.d_month_seq,
        s.s_store_name,
        s.s_city,
        COUNT(*) AS closed_store_cnt
    FROM store s
    JOIN date_dim d_store ON s.s_closed_date_sk = d_store.d_date_sk
    GROUP BY 
        d_store.d_year,
        d_store.d_month_seq,
        s.s_store_name,
        s.s_city
),
web_page_stats_by_month AS (
    SELECT 
        d_cre.d_year AS creation_year,
        d_cre.d_month_seq AS creation_month,
        d_acc.d_year AS access_year,
        d_acc.d_month_seq AS access_month,
        COUNT(DISTINCT wp.wp_web_page_id) AS distinct_pages,
        AVG(date_diff('day', d_cre.d_date, d_acc.d_date)) AS avg_days_between,
        COUNT(*) AS total_page_visits
    FROM web_page wp
    JOIN date_dim d_cre ON wp.wp_creation_date_sk = d_cre.d_date_sk
    JOIN date_dim d_acc ON wp.wp_access_date_sk = d_acc.d_date_sk
    GROUP BY 
        d_cre.d_year,
        d_cre.d_month_seq,
        d_acc.d_year,
        d_acc.d_month_seq
)
SELECT 
    ROW_NUMBER() OVER (ORDER BY r.total_net_loss DESC) AS net_loss_rank,
    r.d_year,
    r.d_month_seq,
    r.i_category,
    r.i_brand,
    r.total_return_amount,
    r.total_net_loss,
    r.return_cnt,
    s.s_store_name,
    s.s_city,
    s.closed_store_cnt,
    wp.distinct_pages,
    wp.avg_days_between,
    wp.total_page_visits
FROM returns_by_month r
LEFT JOIN store_closures_by_month s
    ON r.d_year = s.d_year AND r.d_month_seq = s.d_month_seq
LEFT JOIN web_page_stats_by_month wp
    ON r.d_year = wp.creation_year AND r.d_month_seq = wp.creation_month
ORDER BY r.total_net_loss DESC
LIMIT 100
