WITH sales_base AS (
    SELECT
        ss.*, 
        array[ss.ss_quantity, ss.ss_ext_sales_price] AS qty_price_arr
    FROM store_sales ss
),
returns_base AS (
    SELECT
        cr.*, 
        r.r_reason_desc
    FROM catalog_returns cr
    LEFT JOIN reason r
        ON cr.cr_reason_sk = r.r_reason_sk
)
SELECT
    s.s_store_name,
    d_year.d_year,
    ib.ib_lower_bound,
    SUM(ssb.ss_ext_sales_price) AS total_sales,
    SUM(rb.cr_net_loss) AS total_loss,
    COUNT(DISTINCT ssb.ss_ticket_number) AS unique_tickets,
    COUNT(*) AS row_cnt
FROM sales_base ssb
JOIN date_dim d_year
    ON ssb.ss_sold_date_sk = d_year.d_date_sk
JOIN time_dim t_time
    ON ssb.ss_sold_time_sk = t_time.t_time_sk
JOIN customer_demographics cd_cust
    ON ssb.ss_cdemo_sk = cd_cust.cd_demo_sk
JOIN household_demographics hd_cust
    ON ssb.ss_hdemo_sk = hd_cust.hd_demo_sk
JOIN income_band ib
    ON hd_cust.hd_income_band_sk = ib.ib_income_band_sk
JOIN store s
    ON ssb.ss_store_sk = s.s_store_sk
JOIN returns_base rb
    ON ssb.ss_sold_date_sk = rb.cr_returned_date_sk
   AND ssb.ss_sold_time_sk = rb.cr_returned_time_sk
JOIN date_dim d_ret
    ON rb.cr_returned_date_sk = d_ret.d_date_sk
JOIN time_dim t_ret
    ON rb.cr_returned_time_sk = t_ret.t_time_sk
JOIN customer_demographics cd_refund
    ON rb.cr_refunded_cdemo_sk = cd_refund.cd_demo_sk
JOIN household_demographics hd_refund
    ON rb.cr_refunded_hdemo_sk = hd_refund.hd_demo_sk
JOIN customer_demographics cd_returning
    ON rb.cr_returning_cdemo_sk = cd_returning.cd_demo_sk
JOIN household_demographics hd_returning
    ON rb.cr_returning_hdemo_sk = hd_returning.hd_demo_sk
JOIN store s_closed
    ON s.s_closed_date_sk = d_ret.d_date_sk
CROSS JOIN UNNEST(ssb.qty_price_arr) WITH ORDINALITY AS u(qty_or_price, pos)
WHERE cd_cust.cd_gender = 'F'
  AND s.s_tax_percentage > 0.05
  AND d_year.d_year BETWEEN 1998 AND 2002
GROUP BY ROLLUP (s.s_store_name, d_year.d_year, ib.ib_lower_bound)
ORDER BY total_sales DESC
LIMIT 100
