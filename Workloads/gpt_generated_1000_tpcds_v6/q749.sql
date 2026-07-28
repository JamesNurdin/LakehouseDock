WITH sales_agg AS (
    SELECT
        cc.cc_call_center_sk,
        cc.cc_name,
        i.i_category,
        t.t_hour,
        SUM(cs.cs_net_paid) AS sum_cs_net_paid,
        SUM(ss.ss_net_paid) AS sum_ss_net_paid,
        SUM(COALESCE(cr.cr_return_amount, 0)) AS sum_return_amount,
        COUNT(DISTINCT cs.cs_order_number) AS order_cnt,
        COUNT(DISTINCT cr.cr_return_quantity) AS return_cnt,
        CASE WHEN SUM(cs.cs_net_paid) > 0 THEN SUM(cr.cr_return_amount) / SUM(cs.cs_net_paid) ELSE 0 END AS return_rate,
        ROW_NUMBER() OVER (PARTITION BY cc.cc_name ORDER BY SUM(cs.cs_net_paid) DESC) AS rn
    FROM catalog_sales cs
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN time_dim t ON cs.cs_sold_time_sk = t.t_time_sk
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    LEFT JOIN store_sales ss ON ss.ss_item_sk = i.i_item_sk
        AND ss.ss_sold_time_sk = t.t_time_sk
    LEFT JOIN catalog_returns cr ON cr.cr_order_number = cs.cs_order_number
        AND cr.cr_item_sk = i.i_item_sk
    LEFT JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    LEFT JOIN web_page wp ON wp.wp_customer_sk = c.c_customer_sk
    LEFT JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk
    WHERE
        cc.cc_state = 'CA'
        AND i.i_current_price > 100
        AND c.c_preferred_cust_flag = 'Y'
        AND hd.hd_vehicle_count >= 2
        AND ib.ib_lower_bound >= 50000
        AND r.r_reason_desc LIKE '%color%'
        AND wp.wp_image_count >= 3
        AND inv.inv_quantity_on_hand > 0
        AND t.t_hour BETWEEN 9 AND 17
    GROUP BY
        cc.cc_call_center_sk,
        cc.cc_name,
        i.i_category,
        t.t_hour
)
SELECT
    cc_name,
    AVG(return_rate) AS avg_return_rate,
    SUM(sum_cs_net_paid) AS total_cs_net_paid,
    SUM(sum_ss_net_paid) AS total_ss_net_paid,
    COUNT(*) AS category_hour_cnt
FROM sales_agg
WHERE rn = 1
GROUP BY cc_name
ORDER BY avg_return_rate DESC
LIMIT 100
