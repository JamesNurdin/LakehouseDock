WITH base AS (
    SELECT
        cp.cp_catalog_page_id,
        cp.cp_description,
        cr.cr_return_amount,
        cr.cr_return_quantity,
        sm.sm_ship_mode_id,
        t_cr.t_hour AS cr_hour,
        i.i_item_sk,
        i.i_item_id,
        i.i_current_price,
        hd_ref.hd_income_band_sk AS refunded_income_band,
        hd_ret.hd_income_band_sk AS returning_income_band,
        ss.ss_net_paid,
        ss.ss_quantity,
        p.p_promo_name,
        ss.ss_sold_date_sk,
        t_ss.t_hour AS ss_hour,
        wr.wr_return_amt,
        wr.wr_return_quantity,
        hd_wr_ref.hd_income_band_sk AS wr_refunded_income_band,
        hd_wr_ret.hd_income_band_sk AS wr_returning_income_band
    FROM catalog_returns cr
    JOIN catalog_page cp
      ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN ship_mode sm
      ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN time_dim t_cr
      ON cr.cr_returned_time_sk = t_cr.t_time_sk
    JOIN item i
      ON cr.cr_item_sk = i.i_item_sk
    JOIN household_demographics hd_ref
      ON cr.cr_refunded_hdemo_sk = hd_ref.hd_demo_sk
    JOIN household_demographics hd_ret
      ON cr.cr_returning_hdemo_sk = hd_ret.hd_demo_sk
    LEFT JOIN store_sales ss
      ON ss.ss_item_sk = i.i_item_sk
     AND ss.ss_sold_time_sk = t_cr.t_time_sk
    LEFT JOIN promotion p
      ON ss.ss_promo_sk = p.p_promo_sk
    LEFT JOIN time_dim t_ss
      ON ss.ss_sold_time_sk = t_ss.t_time_sk
    LEFT JOIN household_demographics hd_ss
      ON ss.ss_hdemo_sk = hd_ss.hd_demo_sk
    LEFT JOIN web_returns wr
      ON wr.wr_item_sk = i.i_item_sk
     AND wr.wr_returned_time_sk = t_cr.t_time_sk
    LEFT JOIN household_demographics hd_wr_ref
      ON wr.wr_refunded_hdemo_sk = hd_wr_ref.hd_demo_sk
    LEFT JOIN household_demographics hd_wr_ret
      ON wr.wr_returning_hdemo_sk = hd_wr_ret.hd_demo_sk
),
agg1 AS (
    SELECT
        b.cp_catalog_page_id,
        b.p_promo_name,
        b.i_item_id,
        SUM(b.cr_return_amount) AS catalog_return,
        SUM(b.wr_return_amt) AS web_return,
        lt.total_sales
    FROM base b
    CROSS JOIN LATERAL (
        SELECT SUM(ss2.ss_ext_sales_price) AS total_sales
        FROM store_sales ss2
        WHERE ss2.ss_item_sk = b.i_item_sk
    ) lt
    WHERE b.cr_hour < 12
    GROUP BY b.cp_catalog_page_id, b.p_promo_name, b.i_item_id, lt.total_sales
),
agg2 AS (
    SELECT
        b.cp_catalog_page_id,
        b.p_promo_name,
        b.i_item_id,
        SUM(b.cr_return_amount) AS catalog_return,
        SUM(b.wr_return_amt) AS web_return,
        lt.total_sales
    FROM base b
    CROSS JOIN LATERAL (
        SELECT SUM(ss2.ss_ext_sales_price) AS total_sales
        FROM store_sales ss2
        WHERE ss2.ss_item_sk = b.i_item_sk
    ) lt
    WHERE b.cr_hour >= 12
    GROUP BY b.cp_catalog_page_id, b.p_promo_name, b.i_item_id, lt.total_sales
)
SELECT
    cp_catalog_page_id,
    p_promo_name,
    SUM(catalog_return) AS total_catalog_return,
    SUM(web_return) AS total_web_return,
    SUM(total_sales) AS total_sales_across_items
FROM (
    SELECT * FROM agg1
    UNION DISTINCT
    SELECT * FROM agg2
) u
GROUP BY cp_catalog_page_id, p_promo_name
ORDER BY total_catalog_return DESC
LIMIT 20
