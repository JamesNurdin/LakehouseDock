WITH sr_agg AS (
    SELECT
        sr.sr_returned_date_sk AS date_sk,
        sr.sr_return_time_sk AS time_sk,
        sr.sr_item_sk AS item_sk,
        sr.sr_hdemo_sk AS hdemo_sk,
        SUM(sr.sr_return_amt) AS sum_sr_return_amt,
        SUM(sr.sr_net_loss) AS sum_sr_net_loss,
        COUNT(*) AS cnt_sr
    FROM store_returns sr
    WHERE sr.sr_return_quantity > 1
    GROUP BY sr.sr_returned_date_sk, sr.sr_return_time_sk, sr.sr_item_sk, sr.sr_hdemo_sk
),
cr_agg AS (
    SELECT
        cr.cr_returned_date_sk AS date_sk,
        cr.cr_returned_time_sk AS time_sk,
        cr.cr_item_sk AS item_sk,
        cr.cr_refunded_hdemo_sk AS hdemo_sk,
        cr.cr_catalog_page_sk AS catalog_page_sk,
        SUM(cr.cr_return_amount) AS sum_cr_return_amt,
        SUM(cr.cr_net_loss) AS sum_cr_net_loss,
        COUNT(*) AS cnt_cr
    FROM catalog_returns cr
    WHERE cr.cr_return_ship_cost > 1000.00
      AND cr.cr_return_quantity > 0
    GROUP BY cr.cr_returned_date_sk, cr.cr_returned_time_sk, cr.cr_item_sk, cr.cr_refunded_hdemo_sk, cr.cr_catalog_page_sk
),
wr_agg AS (
    SELECT
        wr.wr_returned_date_sk AS date_sk,
        wr.wr_returned_time_sk AS time_sk,
        wr.wr_item_sk AS item_sk,
        wr.wr_refunded_hdemo_sk AS hdemo_sk,
        wr.wr_web_page_sk AS web_page_sk,
        SUM(wr.wr_return_amt) AS sum_wr_return_amt,
        SUM(wr.wr_net_loss) AS sum_wr_net_loss,
        COUNT(*) AS cnt_wr
    FROM web_returns wr
    WHERE wr.wr_return_amt > 10.00
    GROUP BY wr.wr_returned_date_sk, wr.wr_returned_time_sk, wr.wr_item_sk, wr.wr_refunded_hdemo_sk, wr.wr_web_page_sk
)
SELECT
    ws.web_site_id,
    ws.web_name,
    ws.web_city,
    d.d_year,
    d.d_month_seq,
    i.i_brand,
    i.i_category,
    ib.ib_income_band_sk,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    cp.cp_department,
    wp.wp_type,
    t.t_hour,
    SUM(sr_agg.sum_sr_return_amt) AS total_store_return_amt,
    SUM(cr_agg.sum_cr_return_amt) AS total_catalog_return_amt,
    SUM(wr_agg.sum_wr_return_amt) AS total_web_return_amt,
    (SUM(sr_agg.sum_sr_net_loss) + SUM(cr_agg.sum_cr_net_loss) + SUM(wr_agg.sum_wr_net_loss)) AS total_net_loss,
    COUNT(DISTINCT sr_agg.item_sk) AS distinct_items_returned,
    AVG(sr_agg.cnt_sr) AS avg_store_returns_per_group
FROM sr_agg
JOIN cr_agg
    ON sr_agg.date_sk = cr_agg.date_sk
   AND sr_agg.item_sk = cr_agg.item_sk
   AND sr_agg.hdemo_sk = cr_agg.hdemo_sk
JOIN wr_agg
    ON sr_agg.date_sk = wr_agg.date_sk
   AND sr_agg.item_sk = wr_agg.item_sk
   AND sr_agg.hdemo_sk = wr_agg.hdemo_sk
JOIN date_dim d
    ON sr_agg.date_sk = d.d_date_sk
JOIN time_dim t
    ON sr_agg.time_sk = t.t_time_sk
JOIN item i
    ON sr_agg.item_sk = i.i_item_sk
JOIN household_demographics hd
    ON sr_agg.hdemo_sk = hd.hd_demo_sk
JOIN income_band ib
    ON hd.hd_income_band_sk = ib.ib_income_band_sk
JOIN catalog_page cp
    ON cr_agg.catalog_page_sk = cp.cp_catalog_page_sk
JOIN web_page wp
    ON wr_agg.web_page_sk = wp.wp_web_page_sk
JOIN web_site ws
    ON ws.web_open_date_sk = d.d_date_sk
WHERE
    d.d_year = 2002
    AND ib.ib_upper_bound = 90000
    AND ws.web_class = 'Unknown'
    AND ws.web_street_name = 'Washington'
    AND i.i_current_price > 50.00
GROUP BY
    ws.web_site_id,
    ws.web_name,
    ws.web_city,
    d.d_year,
    d.d_month_seq,
    i.i_brand,
    i.i_category,
    ib.ib_income_band_sk,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    cp.cp_department,
    wp.wp_type,
    t.t_hour
HAVING
    SUM(sr_agg.sum_sr_return_amt) > 10000
ORDER BY
    total_net_loss DESC,
    ws.web_site_id
