WITH sales_summary AS (
    SELECT
        cs.cs_item_sk,
        cs.cs_order_number,
        cs.cs_promo_sk,
        cs.cs_warehouse_sk,
        cs.cs_sold_date_sk,
        SUM(cs.cs_net_paid) AS total_net_paid,
        SUM(cs.cs_quantity) AS total_quantity,
        COUNT(*) AS sales_cnt
    FROM catalog_sales cs
    WHERE cs.cs_sold_date_sk IN (
        SELECT d_date_sk
        FROM date_dim
        WHERE d_fy_week_seq = 5
    )
    GROUP BY
        cs.cs_item_sk,
        cs.cs_order_number,
        cs.cs_promo_sk,
        cs.cs_warehouse_sk,
        cs.cs_sold_date_sk
)
SELECT
    d_sales.d_year,
    w.w_warehouse_name,
    r.r_reason_desc,
    SUM(cr.cr_net_loss) AS total_return_loss,
    SUM(wr.wr_net_loss) AS total_web_return_loss,
    SUM(ss.total_net_paid) AS total_sales_net_paid,
    COUNT(DISTINCT c.c_customer_sk) AS distinct_customers,
    CASE WHEN ib.ib_upper_bound > 100000 THEN 'Very High' ELSE 'Standard' END AS income_category,
    AVG(ss.total_quantity) AS avg_quantity_per_order
FROM catalog_returns cr
JOIN sales_summary ss
    ON cr.cr_order_number = ss.cs_order_number
   AND cr.cr_item_sk = ss.cs_item_sk
JOIN catalog_sales cs
    ON cs.cs_order_number = ss.cs_order_number
   AND cs.cs_item_sk = ss.cs_item_sk
JOIN date_dim d_ret
    ON cr.cr_returned_date_sk = d_ret.d_date_sk
JOIN time_dim t_ret
    ON cr.cr_returned_time_sk = t_ret.t_time_sk
JOIN warehouse w
    ON cr.cr_warehouse_sk = w.w_warehouse_sk
JOIN reason r
    ON cr.cr_reason_sk = r.r_reason_sk
JOIN customer c
    ON cr.cr_refunded_customer_sk = c.c_customer_sk
JOIN customer_address ca
    ON cr.cr_refunded_addr_sk = ca.ca_address_sk
JOIN household_demographics hd
    ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
JOIN income_band ib
    ON hd.hd_income_band_sk = ib.ib_income_band_sk
JOIN promotion p
    ON ss.cs_promo_sk = p.p_promo_sk
JOIN date_dim d_sales
    ON ss.cs_sold_date_sk = d_sales.d_date_sk
JOIN web_returns wr
    ON wr.wr_returned_date_sk = d_ret.d_date_sk
JOIN time_dim t_web
    ON wr.wr_returned_time_sk = t_web.t_time_sk
WHERE
    t_ret.t_shift = 'first'
    AND ib.ib_lower_bound >= 60000
    AND p.p_channel_radio = 'N'
    AND r.r_reason_desc = 'Damaged'
    AND NOT EXISTS (
        SELECT 1
        FROM promotion p2
        WHERE p2.p_item_sk = ss.cs_item_sk
          AND p2.p_discount_active = 'Y'
    )
GROUP BY
    d_sales.d_year,
    w.w_warehouse_name,
    r.r_reason_desc,
    CASE WHEN ib.ib_upper_bound > 100000 THEN 'Very High' ELSE 'Standard' END
HAVING
    SUM(cr.cr_net_loss) > 5000
ORDER BY
    d_sales.d_year DESC,
    total_return_loss DESC
