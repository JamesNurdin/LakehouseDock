WITH sales AS (
    SELECT
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_education_status,
        cd.cd_marital_status,
        COUNT(DISTINCT cs.cs_order_number) AS num_orders,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        SUM(cs.cs_net_profit) AS total_profit,
        SUM(cs.cs_ext_discount_amt) AS total_discount,
        SUM(cs.cs_quantity) AS total_quantity
    FROM catalog_sales cs
    JOIN customer_demographics cd
        ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    WHERE cs.cs_sold_date_sk BETWEEN 2450900 AND 2451150
    GROUP BY cd.cd_demo_sk, cd.cd_gender, cd.cd_education_status, cd.cd_marital_status
),
catalog_ret AS (
    SELECT
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_education_status,
        cd.cd_marital_status,
        SUM(cr.cr_return_amount) AS total_cat_return_amount,
        SUM(cr.cr_return_quantity) AS total_cat_return_quantity,
        SUM(cr.cr_net_loss) AS total_cat_net_loss
    FROM catalog_returns cr
    JOIN customer_demographics cd
        ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
    WHERE cr.cr_returned_date_sk BETWEEN 2450900 AND 2451150
    GROUP BY cd.cd_demo_sk, cd.cd_gender, cd.cd_education_status, cd.cd_marital_status
),
store_ret AS (
    SELECT
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_education_status,
        cd.cd_marital_status,
        SUM(sr.sr_return_amt) AS total_store_return_amount,
        SUM(sr.sr_return_quantity) AS total_store_return_quantity,
        SUM(sr.sr_net_loss) AS total_store_net_loss
    FROM store_returns sr
    JOIN customer_demographics cd
        ON sr.sr_cdemo_sk = cd.cd_demo_sk
    WHERE sr.sr_returned_date_sk BETWEEN 2450900 AND 2451150
    GROUP BY cd.cd_demo_sk, cd.cd_gender, cd.cd_education_status, cd.cd_marital_status
)
SELECT
    s.cd_gender,
    s.cd_education_status,
    s.cd_marital_status,
    s.num_orders,
    s.total_sales,
    s.total_profit,
    COALESCE(cr.total_cat_return_amount, 0) AS total_cat_return_amount,
    COALESCE(st.total_store_return_amount, 0) AS total_store_return_amount,
    s.total_sales - COALESCE(cr.total_cat_return_amount, 0) - COALESCE(st.total_store_return_amount, 0) AS net_revenue,
    (s.total_sales - COALESCE(cr.total_cat_return_amount, 0) - COALESCE(st.total_store_return_amount, 0)) / NULLIF(s.total_sales, 0) AS net_revenue_ratio,
    s.total_discount / NULLIF(s.total_quantity, 0) AS avg_discount_per_item,
    ROW_NUMBER() OVER (ORDER BY s.total_profit DESC) AS profit_rank
FROM sales s
LEFT JOIN catalog_ret cr
    ON s.cd_demo_sk = cr.cd_demo_sk
LEFT JOIN store_ret st
    ON s.cd_demo_sk = st.cd_demo_sk
WHERE s.total_sales > 50000
  AND s.total_profit > 10000
ORDER BY net_revenue DESC
LIMIT 100
