WITH returns_agg AS (
    SELECT
        cr.cr_returned_date_sk,
        cr.cr_returned_time_sk,
        cr.cr_return_amount,
        cr.cr_return_tax,
        cr.cr_return_amt_inc_tax,
        cr.cr_fee,
        cr.cr_net_loss,
        cr.cr_order_number,
        CASE WHEN cr.cr_return_amount > 1000 THEN 'High' ELSE 'Low' END AS return_category
    FROM catalog_returns cr
    JOIN date_dim d_ret ON cr.cr_returned_date_sk = d_ret.d_date_sk
    JOIN time_dim t_ret ON cr.cr_returned_time_sk = t_ret.t_time_sk
    JOIN customer c_refund ON cr.cr_refunded_customer_sk = c_refund.c_customer_sk
    JOIN household_demographics hd_refund ON cr.cr_refunded_hdemo_sk = hd_refund.hd_demo_sk
    WHERE d_ret.d_year = 2001
      AND t_ret.t_hour BETWEEN 9 AND 17
      AND hd_refund.hd_vehicle_count >= 2
),
joined_data AS (
    SELECT
        d_date.d_year,
        d_date.d_month_seq,
        s.s_store_name,
        p.p_promo_name,
        ra.return_category,
        ra.cr_return_amount,
        ws.ws_net_paid_inc_tax,
        ws.ws_order_number
    FROM returns_agg ra
    JOIN web_sales ws
        ON ws.ws_sold_date_sk = ra.cr_returned_date_sk
        AND ws.ws_sold_time_sk = ra.cr_returned_time_sk
    JOIN date_dim d_date
        ON ra.cr_returned_date_sk = d_date.d_date_sk
    JOIN promotion p
        ON ws.ws_promo_sk = p.p_promo_sk
    JOIN store s
        ON s.s_closed_date_sk = d_date.d_date_sk
    JOIN household_demographics hd_ws
        ON ws.ws_bill_hdemo_sk = hd_ws.hd_demo_sk
    JOIN income_band ib
        ON hd_ws.hd_income_band_sk = ib.ib_income_band_sk
    WHERE p.p_discount_active = 'Y'
      AND s.s_state = 'CA'
      AND ib.ib_lower_bound >= 50000
      AND ws.ws_net_paid_inc_tax > 500
)
SELECT
    d_year,
    d_month_seq,
    s_store_name,
    p_promo_name,
    return_category,
    SUM(cr_return_amount) AS total_return_amount,
    SUM(ws_net_paid_inc_tax) AS total_sales_inc_tax,
    COUNT(DISTINCT ws_order_number) AS distinct_orders,
    AVG(ws_net_paid_inc_tax) AS avg_sales_inc_tax,
    MIN(ws_net_paid_inc_tax) AS min_sales_inc_tax,
    MAX(ws_net_paid_inc_tax) AS max_sales_inc_tax,
    ROW_NUMBER() OVER (PARTITION BY d_year ORDER BY d_month_seq) AS rn_month
FROM joined_data
GROUP BY d_year, d_month_seq, s_store_name, p_promo_name, return_category
ORDER BY total_return_amount DESC
LIMIT 100
