WITH ws_agg AS (
    SELECT
        ws_item_sk,
        ws_sold_date_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        SUM(ws_quantity) AS total_qty
    FROM web_sales
    GROUP BY ws_item_sk, ws_sold_date_sk
)
SELECT
    d_ret.d_year,
    i.i_category,
    cd.cd_credit_rating,
    hd.hd_income_band_sk,
    p.p_promo_name,
    ws_agg.total_sales,
    ws_agg.total_qty,
    COUNT(DISTINCT cr.cr_order_number) AS distinct_return_orders,
    AVG(ws.ws_ext_discount_amt) AS avg_discount_amount
FROM catalog_returns cr
JOIN date_dim d_ret
    ON cr.cr_returned_date_sk = d_ret.d_date_sk
JOIN time_dim t_ret
    ON cr.cr_returned_time_sk = t_ret.t_time_sk
JOIN item i
    ON cr.cr_item_sk = i.i_item_sk
JOIN customer_demographics cd
    ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
JOIN household_demographics hd
    ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
JOIN ws_agg
    ON ws_agg.ws_item_sk = i.i_item_sk
JOIN date_dim d_sales
    ON ws_agg.ws_sold_date_sk = d_sales.d_date_sk
JOIN web_sales ws
    ON ws.ws_item_sk = i.i_item_sk
   AND ws.ws_sold_date_sk = d_sales.d_date_sk
JOIN promotion p
    ON ws.ws_promo_sk = p.p_promo_sk
JOIN date_dim d_promo_start
    ON p.p_start_date_sk = d_promo_start.d_date_sk
JOIN date_dim d_promo_end
    ON p.p_end_date_sk = d_promo_end.d_date_sk
JOIN web_page wp
    ON ws.ws_web_page_sk = wp.wp_web_page_sk
JOIN date_dim d_page_creation
    ON wp.wp_creation_date_sk = d_page_creation.d_date_sk
JOIN date_dim d_page_access
    ON wp.wp_access_date_sk = d_page_access.d_date_sk
GROUP BY
    d_ret.d_year,
    i.i_category,
    cd.cd_credit_rating,
    hd.hd_income_band_sk,
    p.p_promo_name,
    ws_agg.total_sales,
    ws_agg.total_qty
ORDER BY
    d_ret.d_year DESC,
    ws_agg.total_sales DESC
LIMIT 100
