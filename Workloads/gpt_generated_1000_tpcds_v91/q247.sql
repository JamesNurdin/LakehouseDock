WITH filtered_data AS (
    SELECT
        cs.cs_sold_date_sk,
        cs.cs_sold_time_sk,
        cs.cs_quantity,
        cs.cs_net_paid,
        cs.cs_ext_tax,
        cs.cs_ext_discount_amt,
        cs.cs_net_profit,
        cs.cs_order_number,
        cc.cc_name,
        cc.cc_state,
        p.p_promo_name,
        p.p_channel_dmail,
        p.p_channel_press,
        i.i_category,
        i.i_current_price,
        ib.ib_lower_bound,
        r.r_reason_desc,
        td.t_hour,
        c.c_customer_id,
        cr.cr_return_amount,
        sr.sr_return_amt
    FROM catalog_sales cs
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN catalog_returns cr ON cr.cr_order_number = cs.cs_order_number
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN store_returns sr ON sr.sr_item_sk = i.i_item_sk
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN time_dim td ON cs.cs_sold_time_sk = td.t_time_sk
    WHERE cc.cc_state = 'CA'
      AND p.p_channel_dmail = 'Y'
      AND p.p_channel_press = 'N'
      AND ib.ib_lower_bound >= 100000
      AND i.i_current_price > 100.00
      AND td.t_hour BETWEEN 9 AND 17
)
SELECT
    cc_name,
    p_promo_name,
    i_category,
    r_reason_desc,
    t_hour,
    SUM(cs_net_paid) AS total_sales,
    SUM(cs_ext_tax) AS total_sales_tax,
    SUM(cs_ext_discount_amt) AS total_discount,
    SUM(cs_quantity) AS total_quantity_sold,
    SUM(cs_net_profit) AS total_net_profit,
    SUM(cr_return_amount) AS total_catalog_return_amount,
    SUM(sr_return_amt) AS total_store_return_amount,
    COUNT(DISTINCT c_customer_id) AS distinct_customers,
    COUNT(DISTINCT cs_order_number) AS distinct_orders,
    AVG(i_current_price) AS avg_item_price,
    MIN(cs_sold_date_sk) AS min_sold_date_sk,
    MAX(cs_sold_date_sk) AS max_sold_date_sk,
    ROW_NUMBER() OVER (ORDER BY SUM(cs_net_paid) DESC) AS rn
FROM filtered_data
GROUP BY
    cc_name,
    p_promo_name,
    i_category,
    r_reason_desc,
    t_hour
ORDER BY total_sales DESC
LIMIT 100
