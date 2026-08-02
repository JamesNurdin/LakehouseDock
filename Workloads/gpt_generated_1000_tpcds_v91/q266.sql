WITH catalog_agg AS (
    SELECT
        cs.cs_bill_customer_sk AS customer_sk,
        cs.cs_item_sk AS item_sk,
        cs.cs_promo_sk AS promo_sk,
        cs.cs_bill_hdemo_sk AS hdemo_sk,
        SUM(cs.cs_ext_sales_price) AS total_catalog_sales,
        SUM(cs.cs_ext_discount_amt) AS total_catalog_discount,
        COUNT(*) AS catalog_order_cnt
    FROM tpcds.catalog_sales cs
    JOIN tpcds.customer c
        ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN tpcds.customer_demographics cd
        ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN tpcds.household_demographics hd
        ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN tpcds.income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN tpcds.item i
        ON cs.cs_item_sk = i.i_item_sk
    JOIN tpcds.promotion p
        ON cs.cs_promo_sk = p.p_promo_sk
    JOIN tpcds.catalog_page cp
        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    WHERE
        cd.cd_dep_count = 3
        AND cd.cd_purchase_estimate >= 5000
        AND ib.ib_upper_bound <= 80000
        AND p.p_channel_catalog = 'Y'
        AND p.p_purpose = 'Promotion'
        AND cp.cp_department = 'Electronics'
    GROUP BY
        cs.cs_bill_customer_sk,
        cs.cs_item_sk,
        cs.cs_promo_sk,
        cs.cs_bill_hdemo_sk
),
store_agg AS (
    SELECT
        ss.ss_customer_sk AS customer_sk,
        ss.ss_item_sk AS item_sk,
        ss.ss_promo_sk AS promo_sk,
        ss.ss_hdemo_sk AS hdemo_sk,
        SUM(ss.ss_ext_sales_price) AS total_store_sales,
        SUM(ss.ss_ext_discount_amt) AS total_store_discount,
        COUNT(*) AS store_ticket_cnt,
        s.s_store_name
    FROM tpcds.store_sales ss
    JOIN tpcds.customer c
        ON ss.ss_customer_sk = c.c_customer_sk
    JOIN tpcds.customer_demographics cd
        ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN tpcds.household_demographics hd
        ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN tpcds.income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN tpcds.item i
        ON ss.ss_item_sk = i.i_item_sk
    JOIN tpcds.promotion p
        ON ss.ss_promo_sk = p.p_promo_sk
    LEFT JOIN tpcds.store s
        ON ss.ss_store_sk = s.s_store_sk
    WHERE
        cd.cd_dep_college_count >= 2
        AND cd.cd_marital_status = 'M'
        AND ib.ib_lower_bound >= 30000
        AND p.p_response_target = 1
        AND i.i_color = 'Red'
        AND ss.ss_sales_price > 20
    GROUP BY
        ss.ss_customer_sk,
        ss.ss_item_sk,
        ss.ss_promo_sk,
        ss.ss_hdemo_sk,
        s.s_store_name
)
SELECT
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    i.i_item_id,
    i.i_product_name,
    p.p_promo_name,
    sa.s_store_name,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    ca.total_catalog_sales,
    ca.total_catalog_discount,
    ca.catalog_order_cnt,
    sa.total_store_sales,
    sa.total_store_discount,
    sa.store_ticket_cnt,
    ROW_NUMBER() OVER (ORDER BY (ca.total_catalog_sales + sa.total_store_sales) DESC) AS row_num
FROM catalog_agg ca
JOIN store_agg sa
    ON ca.customer_sk = sa.customer_sk
    AND ca.item_sk = sa.item_sk
    AND ca.promo_sk = sa.promo_sk
    AND ca.hdemo_sk = sa.hdemo_sk
JOIN tpcds.customer c
    ON ca.customer_sk = c.c_customer_sk
JOIN tpcds.item i
    ON ca.item_sk = i.i_item_sk
JOIN tpcds.promotion p
    ON ca.promo_sk = p.p_promo_sk
JOIN tpcds.household_demographics hd
    ON ca.hdemo_sk = hd.hd_demo_sk
JOIN tpcds.income_band ib
    ON hd.hd_income_band_sk = ib.ib_income_band_sk
ORDER BY row_num
LIMIT 100
