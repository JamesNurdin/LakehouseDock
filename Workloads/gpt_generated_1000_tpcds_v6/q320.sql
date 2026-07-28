WITH sales_returns AS (
    SELECT 
        ss.ss_sold_date_sk,
        ss.ss_item_sk,
        ss.ss_store_sk,
        ss.ss_sales_price,
        ss.ss_net_profit,
        cr.cr_returned_date_sk,
        cr.cr_return_amount,
        cr.cr_net_loss,
        hd.hd_income_band_sk,
        hd.hd_vehicle_count,
        p.p_promo_id,
        p.p_discount_active,
        td.t_hour,
        td.t_sub_shift,
        ss.ss_ext_wholesale_cost
    FROM store_sales ss
    JOIN time_dim td
        ON ss.ss_sold_time_sk = td.t_time_sk
    JOIN household_demographics hd
        ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN promotion p
        ON ss.ss_promo_sk = p.p_promo_sk
    JOIN catalog_returns cr
        ON cr.cr_returned_time_sk = td.t_time_sk
    WHERE td.t_sub_shift IN ('morning', 'afternoon')
      AND p.p_item_sk IN (218410, 207529)
      AND ss.ss_ext_wholesale_cost > 1000
      AND hd.hd_vehicle_count >= 2
)
,
aggregated AS (
    SELECT 
        sr.ss_store_sk,
        sr.p_promo_id,
        sr.t_hour,
        SUM(sr.ss_sales_price) AS total_sales,
        SUM(sr.cr_return_amount) AS total_returns,
        ROW_NUMBER() OVER (PARTITION BY sr.ss_store_sk ORDER BY SUM(sr.ss_sales_price) DESC) AS sales_rank
    FROM sales_returns sr
    GROUP BY ROLLUP (sr.ss_store_sk, sr.p_promo_id, sr.t_hour)
)
(
    SELECT 
        a.ss_store_sk,
        a.p_promo_id,
        a.t_hour,
        a.total_sales,
        a.total_returns,
        a.sales_rank
    FROM aggregated a
    WHERE a.total_sales > 5000
)
UNION ALL
(
    SELECT 
        sr_missing.ss_store_sk,
        sr_missing.p_promo_id,
        sr_missing.t_hour,
        CAST(0 AS double) AS total_sales,
        CAST(0 AS double) AS total_returns,
        CAST(NULL AS integer) AS sales_rank
    FROM (
        SELECT DISTINCT ss_store_sk, p_promo_id, t_hour
        FROM sales_returns
        WHERE ss_store_sk NOT IN (
            SELECT ss_store_sk
            FROM (
                SELECT ss_store_sk
                FROM sales_returns
                GROUP BY ss_store_sk
                HAVING SUM(ss_sales_price) > 5000
            ) t
        )
    ) sr_missing
)
ORDER BY total_sales DESC
LIMIT 100
