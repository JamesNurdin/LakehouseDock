WITH sales_agg AS (
    SELECT
        ss.ss_store_sk,
        ss.ss_sold_date_sk,
        ss.ss_item_sk,
        ss.ss_promo_sk,
        ss.ss_hdemo_sk,
        SUM(ss.ss_ext_sales_price) AS total_sales_amount,
        SUM(ss.ss_net_profit) AS total_net_profit,
        SUM(ss.ss_quantity) AS total_quantity
    FROM store_sales ss
    GROUP BY
        ss.ss_store_sk,
        ss.ss_sold_date_sk,
        ss.ss_item_sk,
        ss.ss_promo_sk,
        ss.ss_hdemo_sk
)
SELECT
    s_sales.s_store_id,
    s_sales.s_store_name,
    d_sales.d_year,
    d_sales.d_month_seq,
    p.p_promo_name,
    r_return.r_reason_desc,
    SUM(sa.total_sales_amount) AS total_sales_amount,
    SUM(sa.total_net_profit) AS total_net_profit,
    SUM(sr.sr_return_amt) AS total_return_amount,
    COUNT(DISTINCT sr.sr_ticket_number) AS return_ticket_count,
    SUM(cr.cr_return_amount) AS total_catalog_return_amount,
    COUNT(DISTINCT cr.cr_order_number) AS catalog_return_count,
    EXISTS (
        SELECT 1
        FROM catalog_returns cr2
        WHERE cr2.cr_item_sk = sa.ss_item_sk
          AND cr2.cr_returned_date_sk = d_sales.d_date_sk
    ) AS has_catalog_return,
    (SELECT ib2.ib_lower_bound
     FROM income_band ib2
     WHERE ib2.ib_income_band_sk = hd_sales.hd_income_band_sk) AS household_income_lower_bound
FROM sales_agg sa
JOIN store s_sales
    ON sa.ss_store_sk = s_sales.s_store_sk
JOIN date_dim d_sales
    ON sa.ss_sold_date_sk = d_sales.d_date_sk
JOIN promotion p
    ON sa.ss_promo_sk = p.p_promo_sk
JOIN date_dim d_promo_start
    ON p.p_start_date_sk = d_promo_start.d_date_sk
JOIN date_dim d_promo_end
    ON p.p_end_date_sk = d_promo_end.d_date_sk
JOIN household_demographics hd_sales
    ON sa.ss_hdemo_sk = hd_sales.hd_demo_sk
JOIN income_band ib_sales
    ON hd_sales.hd_income_band_sk = ib_sales.ib_income_band_sk
LEFT JOIN store_returns sr
    ON sr.sr_item_sk = sa.ss_item_sk
   AND sr.sr_store_sk = s_sales.s_store_sk
LEFT JOIN date_dim d_return
    ON sr.sr_returned_date_sk = d_return.d_date_sk
LEFT JOIN time_dim t_return
    ON sr.sr_return_time_sk = t_return.t_time_sk
LEFT JOIN household_demographics hd_return
    ON sr.sr_hdemo_sk = hd_return.hd_demo_sk
LEFT JOIN reason r_return
    ON sr.sr_reason_sk = r_return.r_reason_sk
LEFT JOIN catalog_returns cr
    ON cr.cr_returned_date_sk = d_sales.d_date_sk
LEFT JOIN time_dim t_catalog
    ON cr.cr_returned_time_sk = t_catalog.t_time_sk
LEFT JOIN household_demographics hd_refunded
    ON cr.cr_refunded_hdemo_sk = hd_refunded.hd_demo_sk
LEFT JOIN household_demographics hd_returning
    ON cr.cr_returning_hdemo_sk = hd_returning.hd_demo_sk
LEFT JOIN reason r_catalog
    ON cr.cr_reason_sk = r_catalog.r_reason_sk
LEFT JOIN date_dim d_store_closed
    ON s_sales.s_closed_date_sk = d_store_closed.d_date_sk
GROUP BY
    s_sales.s_store_id,
    s_sales.s_store_name,
    d_sales.d_year,
    d_sales.d_month_seq,
    d_sales.d_date_sk,
    p.p_promo_name,
    r_return.r_reason_desc,
    hd_sales.hd_income_band_sk,
    sa.ss_item_sk
ORDER BY total_sales_amount DESC
LIMIT 100
