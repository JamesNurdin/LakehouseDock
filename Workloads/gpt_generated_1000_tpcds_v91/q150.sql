WITH
    ss_agg AS (
        SELECT
            ss_customer_sk,
            ss_hdemo_sk,
            SUM(ss_net_profit) AS total_store_profit,
            COUNT(*) AS store_sales_cnt
        FROM
            store_sales
        GROUP BY
            ss_customer_sk,
            ss_hdemo_sk
    ),
    sr_sample AS (
        SELECT *
        FROM store_returns
        TABLESAMPLE BERNOULLI (10)
    ),
    full_returns AS (
        SELECT
            sr.sr_customer_sk,
            sr.sr_return_amt,
            sr.sr_ticket_number,
            r.r_reason_desc
        FROM
            sr_sample sr
            FULL OUTER JOIN reason r
                ON sr.sr_reason_sk = r.r_reason_sk
    ),
    union_returns AS (
        SELECT
            sr_sample.sr_customer_sk AS cust_sk,
            sr_sample.sr_return_amt AS return_amt,
            'store' AS src
        FROM
            sr_sample
        UNION ALL
        SELECT
            cr.cr_refunded_customer_sk AS cust_sk,
            cr.cr_return_amount AS return_amt,
            'catalog' AS src
        FROM
            catalog_returns cr
    )
SELECT
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    c.c_birth_country,
    hd_c.hd_income_band_sk,
    hd_c.hd_buy_potential,
    ss_agg.total_store_profit,
    cs_agg.total_catalog_sales,
    COALESCE(full_ret.r_reason_desc, 'No Reason') AS return_reason,
    cc_sales.cc_name AS sales_call_center,
    cc_return.cc_name AS return_call_center,
    cp_sales.cp_department AS sales_department,
    cp_return.cp_department AS return_department,
    sm_sales.sm_type AS sales_ship_type,
    sm_return.sm_type AS return_ship_type,
    wp.wp_url,
    (SELECT AVG(ss_net_profit) FROM store_sales) AS avg_store_profit,
    EXISTS (SELECT 1 FROM store_returns sr_exists WHERE sr_exists.sr_customer_sk = c.c_customer_sk) AS has_store_return,
    (SELECT SUM(return_amt) FROM union_returns ur WHERE ur.cust_sk = c.c_customer_sk) AS total_return_amount
FROM
    customer c
    JOIN household_demographics hd_c ON c.c_current_hdemo_sk = hd_c.hd_demo_sk
    LEFT JOIN ss_agg ON ss_agg.ss_customer_sk = c.c_customer_sk AND ss_agg.ss_hdemo_sk = hd_c.hd_demo_sk
    LEFT JOIN (
        SELECT
            cs.cs_bill_customer_sk AS cs_customer_sk,
            cs.cs_bill_hdemo_sk AS cs_hdemo_sk,
            SUM(cs.cs_net_paid_inc_tax) AS total_catalog_sales,
            COUNT(*) AS catalog_sales_cnt
        FROM
            catalog_sales cs
        GROUP BY
            cs.cs_bill_customer_sk,
            cs.cs_bill_hdemo_sk
    ) cs_agg ON cs_agg.cs_customer_sk = c.c_customer_sk AND cs_agg.cs_hdemo_sk = hd_c.hd_demo_sk
    LEFT JOIN catalog_sales cs ON cs.cs_bill_customer_sk = c.c_customer_sk
    LEFT JOIN call_center cc_sales ON cs.cs_call_center_sk = cc_sales.cc_call_center_sk
    LEFT JOIN catalog_page cp_sales ON cs.cs_catalog_page_sk = cp_sales.cp_catalog_page_sk
    LEFT JOIN ship_mode sm_sales ON cs.cs_ship_mode_sk = sm_sales.sm_ship_mode_sk
    LEFT JOIN catalog_returns cr ON cr.cr_order_number = cs.cs_order_number
    LEFT JOIN call_center cc_return ON cr.cr_call_center_sk = cc_return.cc_call_center_sk
    LEFT JOIN catalog_page cp_return ON cr.cr_catalog_page_sk = cp_return.cp_catalog_page_sk
    LEFT JOIN ship_mode sm_return ON cr.cr_ship_mode_sk = sm_return.sm_ship_mode_sk
    LEFT JOIN reason r_catalog ON cr.cr_reason_sk = r_catalog.r_reason_sk
    LEFT JOIN web_page wp ON wp.wp_customer_sk = c.c_customer_sk
    LEFT JOIN full_returns full_ret ON full_ret.sr_customer_sk = c.c_customer_sk
WHERE
    NOT EXISTS (
        SELECT 1
        FROM catalog_returns cr_anti
        WHERE cr_anti.cr_refunded_customer_sk = c.c_customer_sk
    )
