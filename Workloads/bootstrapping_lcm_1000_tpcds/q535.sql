WITH returns_agg AS (
    SELECT
        cr.cr_catalog_page_sk,
        cr.cr_item_sk,
        cr.cr_returned_date_sk,
        SUM(cr.cr_return_amount) AS total_return_amount,
        SUM(cr.cr_net_loss) AS total_net_loss,
        COUNT(*) AS return_cnt
    FROM catalog_returns AS cr
    GROUP BY cr.cr_catalog_page_sk, cr.cr_item_sk, cr.cr_returned_date_sk
)
SELECT
    cp.cp_catalog_page_id,
    cp.cp_type,
    i.i_category,
    i.i_brand,
    d_ret.d_year,
    d_ret.d_month_seq,
    d_start.d_date AS page_start_date,
    d_end.d_date AS page_end_date,
    r.total_return_amount,
    r.total_net_loss,
    r.return_cnt,
    COUNT(DISTINCT s.s_store_sk) AS closed_store_cnt,
    SUM(s.s_floor_space) AS total_closed_floor_space,
    AVG(r.total_return_amount) OVER (PARTITION BY i.i_category ORDER BY d_ret.d_year, d_ret.d_month_seq) AS avg_cat_monthly_return_amount
FROM returns_agg AS r
JOIN catalog_page AS cp ON cp.cp_catalog_page_sk = r.cr_catalog_page_sk
JOIN item AS i ON i.i_item_sk = r.cr_item_sk
JOIN date_dim AS d_ret ON d_ret.d_date_sk = r.cr_returned_date_sk
JOIN date_dim AS d_start ON d_start.d_date_sk = cp.cp_start_date_sk
JOIN date_dim AS d_end ON d_end.d_date_sk = cp.cp_end_date_sk
JOIN store AS s ON s.s_closed_date_sk = d_ret.d_date_sk
WHERE cp.cp_type = 'Seasonal'
  AND d_ret.d_year = 2022
GROUP BY
    cp.cp_catalog_page_id,
    cp.cp_type,
    i.i_category,
    i.i_brand,
    d_ret.d_year,
    d_ret.d_month_seq,
    d_start.d_date,
    d_end.d_date,
    r.total_return_amount,
    r.total_net_loss,
    r.return_cnt
ORDER BY d_ret.d_year, d_ret.d_month_seq, cp.cp_catalog_page_id
LIMIT 100
