WITH sales_cte AS (
    SELECT
        cs.cs_order_number,
        cs.cs_item_sk,
        cs.cs_sold_date_sk,
        cs.cs_bill_customer_sk,
        cs.cs_bill_hdemo_sk,
        cs.cs_net_paid,
        cs.cs_ext_sales_price
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
)
SELECT
    d.d_year,
    d.d_month_seq,
    s.s_store_name,
    c.c_customer_id,
    COUNT(DISTINCT sc.cs_order_number) AS orders_cnt,
    SUM(sc.cs_net_paid) AS total_net_paid,
    AVG(cr.cr_net_loss) AS avg_net_loss,
    SUM(CASE WHEN cr.cr_return_quantity > 0 THEN cr.cr_return_amount ELSE 0 END) AS total_return_amount,
    MAX(sr.sr_return_amt) AS max_store_return,
    (
        SELECT MAX(ib2.ib_upper_bound)
        FROM income_band ib2
        WHERE ib2.ib_lower_bound >= 50000
    ) AS max_income_upper
FROM sales_cte sc
JOIN date_dim d ON sc.cs_sold_date_sk = d.d_date_sk
JOIN store_returns sr ON sr.sr_returned_date_sk = d.d_date_sk
JOIN store s ON sr.sr_store_sk = s.s_store_sk
JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
JOIN household_demographics hd ON sr.sr_hdemo_sk = hd.hd_demo_sk
JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
JOIN catalog_returns cr ON cr.cr_returned_date_sk = d.d_date_sk
    AND cr.cr_order_number = sc.cs_order_number
    AND cr.cr_item_sk = sc.cs_item_sk
    AND cr.cr_refunded_customer_sk = c.c_customer_sk
    AND cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
JOIN web_site w ON w.web_open_date_sk = d.d_date_sk
WHERE
    s.s_state = 'CA'
    AND c.c_salutation = 'Mr.'
    AND ib.ib_lower_bound >= 50000
    AND hd.hd_vehicle_count >= 2
    AND w.web_class = 'Retail'
GROUP BY
    d.d_year,
    d.d_month_seq,
    s.s_store_name,
    c.c_customer_id
ORDER BY total_net_paid DESC
LIMIT 100
