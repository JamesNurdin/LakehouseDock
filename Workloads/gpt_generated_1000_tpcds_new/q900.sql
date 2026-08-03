WITH common_item_sk AS (
    SELECT ss_item_sk AS item_sk FROM store_sales
    INTERSECT
    SELECT ws_item_sk FROM web_sales
),
base_union AS (
    SELECT
        ss.ss_sold_date_sk AS date_sk,
        ss.ss_sold_time_sk AS time_sk,
        ss.ss_item_sk AS item_sk,
        ss.ss_hdemo_sk AS hdemo_sk,
        d.d_year,
        d.d_month_seq,
        t.t_shift,
        t.t_sub_shift,
        i.i_category,
        i.i_current_price,
        ss.ss_ext_sales_price AS ext_sales_price
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    WHERE d.d_year = 2001
      AND t.t_shift = 'first'
      AND t.t_sub_shift = 'morning'
      AND t.t_minute = 12
      AND i.i_current_price BETWEEN 10 AND 100
      AND ss.ss_item_sk IN (SELECT item_sk FROM common_item_sk)
    UNION DISTINCT
    SELECT
        ws.ws_sold_date_sk,
        ws.ws_sold_time_sk,
        ws.ws_item_sk,
        ws.ws_bill_hdemo_sk,
        d.d_year,
        d.d_month_seq,
        t.t_shift,
        t.t_sub_shift,
        i.i_category,
        i.i_current_price,
        ws.ws_ext_sales_price
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN time_dim t ON ws.ws_sold_time_sk = t.t_time_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN household_demographics hd ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    WHERE d.d_year = 2001
      AND t.t_shift = 'first'
      AND t.t_sub_shift = 'morning'
      AND wp.wp_max_ad_count >= 2
      AND i.i_current_price BETWEEN 10 AND 100
      AND ws.ws_item_sk IN (SELECT item_sk FROM common_item_sk)
),
agg_rollup AS (
    SELECT
        date_sk,
        d_year,
        i_category,
        hd_income_band_sk,
        SUM(ext_sales_price) AS total_sales,
        COUNT(*) AS txn_count
    FROM (
        SELECT
            bu.date_sk,
            bu.d_year,
            bu.i_category,
            hd.hd_income_band_sk,
            bu.ext_sales_price
        FROM base_union bu
        JOIN household_demographics hd ON bu.hdemo_sk = hd.hd_demo_sk
    ) sub
    GROUP BY ROLLUP (d_year, i_category, hd_income_band_sk, date_sk)
)
SELECT
    agg.d_year                              AS year,
    agg.i_category                          AS category,
    agg.hd_income_band_sk                   AS income_band,
    agg.total_sales,
    agg.txn_count,
    cr_avg.avg_return_amount,
    cr_sum.total_return_amount,
    cp.cp_department
FROM agg_rollup agg
LEFT JOIN LATERAL (
    SELECT AVG(cr_return_amount) AS avg_return_amount
    FROM catalog_returns cr
    WHERE cr.cr_returned_date_sk = agg.date_sk
      AND cr.cr_return_ship_cost > 500
) cr_avg ON TRUE
LEFT JOIN LATERAL (
    SELECT SUM(cr_return_amount) AS total_return_amount
    FROM catalog_returns cr
    WHERE cr.cr_returned_date_sk = agg.date_sk
) cr_sum ON TRUE
LEFT JOIN catalog_returns cr_fil
    ON cr_fil.cr_returned_date_sk = agg.date_sk
   AND cr_fil.cr_return_ship_cost > 500
LEFT JOIN catalog_page cp
    ON cr_fil.cr_catalog_page_sk = cp.cp_catalog_page_sk
WHERE agg.date_sk IS NOT NULL
ORDER BY year DESC, category, income_band
LIMIT 100
