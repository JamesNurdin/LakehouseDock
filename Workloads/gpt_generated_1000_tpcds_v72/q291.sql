WITH base AS (
    SELECT
        d.d_date_sk,
        d.d_year,
        cc.cc_state,
        cp.cp_type,
        p.p_discount_active,
        cr.cr_order_number,
        cr.cr_return_amount,
        cr.cr_net_loss,
        wr.wr_order_number,
        wr.wr_return_amt,
        wr.wr_net_loss,
        s.s_store_name,
        cp.cp_department,
        inv.inv_quantity_on_hand,
        cd.cd_credit_rating,
        ib.ib_lower_bound,
        ca.ca_address_sk
    FROM date_dim d
    JOIN catalog_returns cr ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN web_returns wr ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN time_dim t ON cr.cr_returned_time_sk = t.t_time_sk
        AND wr.wr_returned_time_sk = t.t_time_sk
    JOIN call_center cc ON cc.cc_closed_date_sk = d.d_date_sk
    JOIN catalog_page cp ON cp.cp_catalog_page_sk = cr.cr_catalog_page_sk
        AND cp.cp_start_date_sk = d.d_date_sk
    JOIN store s ON s.s_closed_date_sk = d.d_date_sk
    JOIN inventory inv ON inv.inv_date_sk = d.d_date_sk
    JOIN promotion p ON p.p_start_date_sk = d.d_date_sk
    JOIN customer cust_refund ON cust_refund.c_customer_sk = cr.cr_refunded_customer_sk
    JOIN customer_demographics cd ON cd.cd_demo_sk = cr.cr_refunded_cdemo_sk
    JOIN household_demographics hd ON hd.hd_demo_sk = cr.cr_refunded_hdemo_sk
    JOIN income_band ib ON ib.ib_income_band_sk = hd.hd_income_band_sk
    JOIN customer_address ca ON ca.ca_address_sk = cr.cr_refunded_addr_sk
    WHERE d.d_year = 2001
      AND cc.cc_state = 'CA'
      AND cd.cd_credit_rating = 'Good'
      AND p.p_discount_active = 'Y'
      AND cp.cp_type = 'PROMO'
)
SELECT
    s_store_name,
    cp_department,
    COUNT(DISTINCT cr_order_number) AS catalog_return_orders,
    SUM(cr_return_amount) AS total_catalog_return_amount,
    COUNT(DISTINCT wr_order_number) AS web_return_orders,
    SUM(wr_return_amt) AS total_web_return_amount,
    SUM(inv_quantity_on_hand) AS total_inventory_qty,
    CASE WHEN SUM(cr_net_loss + wr_net_loss) > 10000 THEN 'High' ELSE 'Low' END AS net_loss_category,
    (
        SELECT AVG(ib_upper_bound)
        FROM income_band ib_sub
        WHERE ib_sub.ib_lower_bound >= 50000
    ) AS avg_income_upper_bound
FROM base
GROUP BY s_store_name, cp_department
ORDER BY total_catalog_return_amount DESC
LIMIT 100
