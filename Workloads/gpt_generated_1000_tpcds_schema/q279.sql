WITH ss_agg AS (
    SELECT
        ss_item_sk,
        ss_sold_date_sk,
        SUM(ss_ext_sales_price) AS total_sales,
        SUM(ss_quantity) AS total_qty
    FROM store_sales
    TABLESAMPLE BERNOULLI (10)
    GROUP BY ss_item_sk, ss_sold_date_sk
),
cr_wr AS (
    SELECT
        cr.cr_returned_date_sk,
        cr.cr_returned_time_sk,
        cr.cr_item_sk,
        cr.cr_return_quantity,
        cr.cr_refunded_hdemo_sk,
        wr.wr_returned_time_sk,
        wr.wr_return_quantity,
        wr.wr_refunded_hdemo_sk
    FROM catalog_returns cr
    FULL OUTER JOIN web_returns wr
        ON cr.cr_returned_date_sk = wr.wr_returned_date_sk
)
SELECT DISTINCT
    d_sale.d_year,
    i.i_category,
    i.i_brand,
    p.p_promo_name,
    ss.total_sales,
    ss.total_qty,
    cr_wr.cr_return_quantity,
    cr_wr.wr_return_quantity,
    ws.web_name,
    hd_cr.hd_vehicle_count,
    t_cr.t_meal_time,
    (
        SELECT COUNT(*)
        FROM promotion p2
        WHERE p2.p_item_sk = i.i_item_sk
    ) AS promo_count_for_item,
    v.dummy
FROM ss_agg ss
JOIN date_dim d_sale
    ON ss.ss_sold_date_sk = d_sale.d_date_sk
JOIN item i
    ON ss.ss_item_sk = i.i_item_sk
JOIN promotion p
    ON p.p_item_sk = i.i_item_sk
JOIN date_dim d_promo_start
    ON p.p_start_date_sk = d_promo_start.d_date_sk
JOIN date_dim d_promo_end
    ON p.p_end_date_sk = d_promo_end.d_date_sk
JOIN cr_wr
    ON ss.ss_item_sk = cr_wr.cr_item_sk
JOIN date_dim d_cr
    ON cr_wr.cr_returned_date_sk = d_cr.d_date_sk
LEFT JOIN time_dim t_cr
    ON cr_wr.cr_returned_time_sk = t_cr.t_time_sk
LEFT JOIN household_demographics hd_cr
    ON cr_wr.cr_refunded_hdemo_sk = hd_cr.hd_demo_sk
JOIN web_site ws
    ON ws.web_open_date_sk = d_cr.d_date_sk
JOIN date_dim d_ws_close
    ON ws.web_close_date_sk = d_ws_close.d_date_sk
CROSS JOIN (SELECT 1 AS dummy UNION ALL SELECT 2) AS v
WHERE d_sale.d_year = 2001
ORDER BY ss.total_sales DESC
LIMIT 100
