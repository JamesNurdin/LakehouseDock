/*
Goal: Summarize net paid and order counts by customer, year and income‑band across catalog sales and returns, applying realistic filters, combining two query variants with UNION (distinct), using a FULL OUTER JOIN between returns and sales, and aggregating with multiple GROUPING SETS.
*/
WITH first_part AS (
    SELECT
        c.c_customer_sk                AS c_customer_sk,
        d_sold.d_year                  AS d_year,
        ib.ib_income_band_sk           AS ib_income_band_sk,
        COALESCE(cs.cs_net_paid, 0)    AS net_paid,
        CASE WHEN cs.cs_order_number IS NOT NULL THEN 1 ELSE 0 END AS order_cnt
    FROM catalog_returns cr
    FULL OUTER JOIN catalog_sales cs
        ON cr.cr_order_number = cs.cs_order_number
       AND cr.cr_item_sk        = cs.cs_item_sk
    LEFT JOIN customer c
        ON cs.cs_bill_customer_sk = c.c_customer_sk
    LEFT JOIN date_dim d_sold
        ON cs.cs_sold_date_sk = d_sold.d_date_sk
    LEFT JOIN time_dim t_ret
        ON cr.cr_returned_time_sk = t_ret.t_time_sk
    LEFT JOIN warehouse w
        ON COALESCE(cs.cs_warehouse_sk, cr.cr_warehouse_sk) = w.w_warehouse_sk
    LEFT JOIN promotion p
        ON cs.cs_promo_sk = p.p_promo_sk
    LEFT JOIN reason r
        ON cr.cr_reason_sk = r.r_reason_sk
    LEFT JOIN household_demographics hd
        ON COALESCE(cs.cs_bill_hdemo_sk, cr.cr_refunded_hdemo_sk) = hd.hd_demo_sk
    LEFT JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    LEFT JOIN web_page wp
        ON wp.wp_creation_date_sk = d_sold.d_date_sk
    LEFT JOIN web_site ws
        ON ws.web_open_date_sk = d_sold.d_date_sk
    WHERE d_sold.d_year = 2001
      AND ib.ib_upper_bound > 100000
      AND ws.web_city = 'Seattle'
),
second_part AS (
    SELECT
        c.c_customer_sk                AS c_customer_sk,
        d_sold.d_year                  AS d_year,
        ib.ib_income_band_sk           AS ib_income_band_sk,
        COALESCE(cs.cs_net_paid, 0)    AS net_paid,
        CASE WHEN cs.cs_order_number IS NOT NULL THEN 1 ELSE 0 END AS order_cnt
    FROM catalog_returns cr
    FULL OUTER JOIN catalog_sales cs
        ON cr.cr_order_number = cs.cs_order_number
       AND cr.cr_item_sk        = cs.cs_item_sk
    LEFT JOIN customer c
        ON cs.cs_bill_customer_sk = c.c_customer_sk
    LEFT JOIN date_dim d_sold
        ON cs.cs_sold_date_sk = d_sold.d_date_sk
    LEFT JOIN time_dim t_ret
        ON cr.cr_returned_time_sk = t_ret.t_time_sk
    LEFT JOIN warehouse w
        ON COALESCE(cs.cs_warehouse_sk, cr.cr_warehouse_sk) = w.w_warehouse_sk
    LEFT JOIN promotion p
        ON cs.cs_promo_sk = p.p_promo_sk
    LEFT JOIN reason r
        ON cr.cr_reason_sk = r.r_reason_sk
    LEFT JOIN household_demographics hd
        ON COALESCE(cs.cs_bill_hdemo_sk, cr.cr_refunded_hdemo_sk) = hd.hd_demo_sk
    LEFT JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    LEFT JOIN web_page wp
        ON wp.wp_creation_date_sk = d_sold.d_date_sk
    LEFT JOIN web_site ws
        ON ws.web_open_date_sk = d_sold.d_date_sk
    WHERE d_sold.d_year = 2002
      AND ib.ib_lower_bound <= 50000
      AND ws.web_state = 'CA'
)
SELECT
    c_customer_sk,
    d_year,
    ib_income_band_sk,
    SUM(net_paid)  AS total_net_paid,
    SUM(order_cnt) AS total_orders
FROM (
    SELECT c_customer_sk, d_year, ib_income_band_sk, net_paid, order_cnt FROM first_part
    UNION
    SELECT c_customer_sk, d_year, ib_income_band_sk, net_paid, order_cnt FROM second_part
) u
GROUP BY GROUPING SETS (
    (c_customer_sk, d_year, ib_income_band_sk),
    (c_customer_sk, d_year),
    (c_customer_sk),
    (d_year),
    ()
)
ORDER BY total_net_paid DESC
LIMIT 100
