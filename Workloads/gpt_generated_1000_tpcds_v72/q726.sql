/*
  Goal: Rank each sales date by the combined monetary amount from catalog returns, store returns, and web sales for the 'Books' department in the year 2000 where promotions were active. The query joins all 16 selected TPC‑DS tables, applies three filter predicates, aggregates the amounts, and uses a window function to rank dates within each month.
*/
WITH joined_data AS (
    SELECT
        d1.d_date AS event_date,
        d1.d_month_seq,
        cp.cp_department AS cp_department,
        s.s_store_name AS s_store_name,
        wsite.web_name AS web_site_name,
        cr.cr_return_amount AS cr_return_amount,
        sr.sr_return_amt AS sr_return_amt,
        ws.ws_ext_sales_price AS ws_ext_sales_price
    FROM catalog_returns cr
    JOIN date_dim d1
        ON cr.cr_returned_date_sk = d1.d_date_sk
    JOIN time_dim t1
        ON cr.cr_returned_time_sk = t1.t_time_sk
    JOIN catalog_page cp
        ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN warehouse w
        ON cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN reason r
        ON cr.cr_reason_sk = r.r_reason_sk
    JOIN customer c_ref
        ON cr.cr_refunded_customer_sk = c_ref.c_customer_sk
    JOIN customer_demographics cd_ref
        ON cr.cr_refunded_cdemo_sk = cd_ref.cd_demo_sk
    JOIN household_demographics hd_ref
        ON cr.cr_refunded_hdemo_sk = hd_ref.hd_demo_sk
    JOIN customer c_ret
        ON cr.cr_returning_customer_sk = c_ret.c_customer_sk
    JOIN customer_demographics cd_ret
        ON cr.cr_returning_cdemo_sk = cd_ret.cd_demo_sk
    JOIN household_demographics hd_ret
        ON cr.cr_returning_hdemo_sk = hd_ret.hd_demo_sk
    /* Store returns */
    JOIN store_returns sr
        ON sr.sr_returned_date_sk = d1.d_date_sk
    JOIN time_dim t2
        ON sr.sr_return_time_sk = t2.t_time_sk
    JOIN store s
        ON sr.sr_store_sk = s.s_store_sk
    JOIN reason r2
        ON sr.sr_reason_sk = r2.r_reason_sk
    /* Web sales */
    JOIN web_sales ws
        ON ws.ws_sold_date_sk = d1.d_date_sk
    JOIN time_dim t3
        ON ws.ws_sold_time_sk = t3.t_time_sk
    JOIN web_site wsite
        ON ws.ws_web_site_sk = wsite.web_site_sk
    JOIN promotion p
        ON ws.ws_promo_sk = p.p_promo_sk
    JOIN web_page wp
        ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN warehouse w2
        ON ws.ws_warehouse_sk = w2.w_warehouse_sk
    /* Income band for household demographics */
    JOIN income_band ib
        ON hd_ref.hd_income_band_sk = ib.ib_income_band_sk
    WHERE d1.d_year = 2000
      AND cp.cp_department = 'Books'
      AND p.p_discount_active = 'Y'
)
SELECT
    event_date,
    cp_department,
    s_store_name,
    web_site_name,
    SUM(cr_return_amount)        AS total_return_amount,
    SUM(sr_return_amt)           AS total_store_return_amount,
    SUM(ws_ext_sales_price)      AS total_web_sales_amount,
    (SUM(cr_return_amount) + SUM(sr_return_amt) + SUM(ws_ext_sales_price)) AS total_amount,
    ROW_NUMBER() OVER (
        PARTITION BY d_month_seq
        ORDER BY (SUM(cr_return_amount) + SUM(sr_return_amt) + SUM(ws_ext_sales_price)) DESC
    ) AS month_rank
FROM joined_data
GROUP BY
    event_date,
    cp_department,
    s_store_name,
    web_site_name,
    d_month_seq
ORDER BY total_amount DESC
LIMIT 100
