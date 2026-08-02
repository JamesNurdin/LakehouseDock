WITH joined_data AS (
    SELECT
        ss.ss_sold_date_sk,
        ss.ss_sold_time_sk,
        ss.ss_item_sk,
        ss.ss_customer_sk,
        ss.ss_cdemo_sk,
        ss.ss_net_paid_inc_tax,
        ss.ss_ext_discount_amt,
        ss.ss_ext_list_price,
        td.t_hour,
        c.c_customer_sk,
        c.c_customer_id,
        c.c_birth_country,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        cr.cr_return_amount,
        cr.cr_return_quantity,
        cr.cr_returned_date_sk,
        cc.cc_name,
        cc.cc_gmt_offset,
        r.r_reason_desc
    FROM store_sales ss
    JOIN time_dim td ON ss.ss_sold_time_sk = td.t_time_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN catalog_returns cr ON cr.cr_returning_customer_sk = c.c_customer_sk
        AND cr.cr_returning_cdemo_sk = cd.cd_demo_sk
    JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    WHERE td.t_hour BETWEEN 9 AND 18
      AND cd.cd_purchase_estimate > 6000
      AND cc.cc_gmt_offset BETWEEN -7 AND -3
)
SELECT
    jd.c_customer_id,
    jd.c_birth_country,
    jd.cd_gender,
    jd.cd_marital_status,
    jd.cd_purchase_estimate,
    jd.ss_net_paid_inc_tax,
    jd.ss_ext_discount_amt,
    jd.r_reason_desc,
    jd.cc_name,
    jd.t_hour,
    (
        SELECT SUM(cr2.cr_return_amount)
        FROM catalog_returns cr2
        WHERE cr2.cr_refunded_customer_sk = jd.c_customer_sk
    ) AS total_refunded_amount,
    RANK() OVER (PARTITION BY jd.cd_gender ORDER BY jd.ss_net_paid_inc_tax DESC) AS gender_sales_rank,
    ROW_NUMBER() OVER (PARTITION BY jd.t_hour ORDER BY jd.ss_net_paid_inc_tax DESC) AS hour_sales_row,
    SUM(jd.ss_net_paid_inc_tax) OVER (
        PARTITION BY jd.cd_gender
        ORDER BY jd.ss_net_paid_inc_tax
        ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
    ) AS moving_sum_net_paid_inc_tax_last3
FROM joined_data jd
ORDER BY jd.ss_net_paid_inc_tax DESC, jd.c_customer_id
LIMIT 100
