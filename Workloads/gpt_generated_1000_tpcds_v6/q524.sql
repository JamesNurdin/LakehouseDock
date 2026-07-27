WITH filtered AS (
    SELECT
        cr.cr_returned_date_sk,
        cr.cr_returned_time_sk,
        cr.cr_item_sk,
        cr.cr_ship_mode_sk,
        cr.cr_return_amount,
        cr.cr_net_loss,
        cr.cr_order_number
    FROM catalog_returns cr
    WHERE cr.cr_return_amount > 50
)
SELECT
    d.d_year,
    d.d_month_seq,
    i.i_brand,
    sm.sm_type,
    SUM(f.cr_return_amount) AS total_return_amount,
    SUM(ss.ss_net_paid) AS total_sales,
    AVG(f.cr_return_amount) AS avg_return_amount,
    COUNT(CASE WHEN f.cr_net_loss > 1000 THEN 1 END) AS high_loss_return_cnt
FROM filtered f
JOIN date_dim d
    ON f.cr_returned_date_sk = d.d_date_sk
JOIN time_dim t
    ON f.cr_returned_time_sk = t.t_time_sk
JOIN item i
    ON f.cr_item_sk = i.i_item_sk
JOIN ship_mode sm
    ON f.cr_ship_mode_sk = sm.sm_ship_mode_sk
JOIN store_sales ss
    ON ss.ss_sold_date_sk = d.d_date_sk
JOIN web_site w
    ON w.web_open_date_sk = d.d_date_sk
WHERE d.d_year = 2001
  AND i.i_brand_id = 1003001
  AND sm.sm_type = 'AIR'
GROUP BY
    d.d_year,
    d.d_month_seq,
    i.i_brand,
    sm.sm_type
ORDER BY total_return_amount DESC
LIMIT 100
