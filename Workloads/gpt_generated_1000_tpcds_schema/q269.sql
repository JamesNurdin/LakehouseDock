WITH
    cat_sales_agg AS (
        SELECT
            cs_item_sk,
            cs_order_number,
            cs_promo_sk,
            SUM(cs_net_paid)   AS total_net_paid,
            SUM(cs_net_profit) AS total_net_profit
        FROM catalog_sales
        WHERE cs_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2001)
          AND cs_quantity > 1
          AND cs_sales_price > 0
        GROUP BY cs_item_sk, cs_order_number, cs_promo_sk
    ),
    store_sales_agg AS (
        SELECT
            ss_item_sk,
            ss_store_sk,
            SUM(ss_net_paid)   AS total_net_paid,
            SUM(ss_net_profit) AS total_net_profit
        FROM store_sales
        WHERE ss_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2001)
          AND ss_quantity > 0
        GROUP BY ss_item_sk, ss_store_sk
    )
SELECT
    d.d_year,
    p.p_promo_name,
    r.r_reason_desc,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    cat.total_net_paid,
    st.total_net_paid AS store_total_net_paid,
    ROW_NUMBER() OVER (PARTITION BY d.d_year ORDER BY (cat.total_net_paid + COALESCE(st.total_net_paid, 0)) DESC) AS sales_rank
FROM cat_sales_agg cat
FULL OUTER JOIN catalog_returns cr
    ON cat.cs_order_number = cr.cr_order_number
JOIN warehouse w
    ON cr.cr_warehouse_sk = w.w_warehouse_sk
JOIN ship_mode sm
    ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
JOIN reason r
    ON cr.cr_reason_sk = r.r_reason_sk
JOIN date_dim d
    ON cr.cr_returned_date_sk = d.d_date_sk
JOIN household_demographics hd
    ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
JOIN income_band ib
    ON hd.hd_income_band_sk = ib.ib_income_band_sk
JOIN promotion p
    ON cat.cs_promo_sk = p.p_promo_sk
LEFT JOIN store_sales_agg st
    ON cat.cs_item_sk = st.ss_item_sk
LEFT JOIN store s
    ON st.ss_store_sk = s.s_store_sk
WHERE d.d_month_seq BETWEEN 1200 AND 1300
UNION DISTINCT
SELECT
    d2.d_year,
    CAST(NULL AS varchar)                                     AS p_promo_name,
    r2.r_reason_desc,
    ib2.ib_lower_bound,
    ib2.ib_upper_bound,
    0                                                       AS cat_total_net_paid,
    wr.wr_return_amt                                        AS store_total_net_paid,
    ROW_NUMBER() OVER (PARTITION BY d2.d_year ORDER BY wr.wr_return_amt DESC) AS sales_rank
FROM web_returns wr
JOIN reason r2
    ON wr.wr_reason_sk = r2.r_reason_sk
JOIN date_dim d2
    ON wr.wr_returned_date_sk = d2.d_date_sk
JOIN household_demographics hd2
    ON wr.wr_refunded_hdemo_sk = hd2.hd_demo_sk
JOIN income_band ib2
    ON hd2.hd_income_band_sk = ib2.ib_income_band_sk
JOIN web_page wp
    ON wr.wr_web_page_sk = wp.wp_web_page_sk
JOIN date_dim d3
    ON wp.wp_creation_date_sk = d3.d_date_sk
WHERE d2.d_year = 2001
  AND wp.wp_image_count > 2
  AND ib2.ib_lower_bound > 100000
ORDER BY d_year, sales_rank
