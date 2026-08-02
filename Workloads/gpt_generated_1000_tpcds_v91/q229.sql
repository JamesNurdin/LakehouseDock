WITH base_data AS (
    SELECT
        cs.cs_order_number,
        cs.cs_sold_date_sk,
        cs.cs_quantity,
        cs.cs_sales_price,
        cs.cs_ext_sales_price,
        cs.cs_net_paid,
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        i.i_category,
        i.i_item_id,
        i.i_current_price,
        cr.cr_return_quantity,
        cr.cr_return_amount,
        cr.cr_return_tax,
        cr.cr_fee,
        r.r_reason_desc
    FROM catalog_sales cs
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN catalog_returns cr ON cr.cr_order_number = cs.cs_order_number
        AND cr.cr_item_sk = i.i_item_sk
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    WHERE cs.cs_sold_date_sk BETWEEN 2451280 AND 2451285
      AND i.i_manufact_id IN (212, 294, 338)
      AND r.r_reason_id = 'AAAAAAAAGAAAAAAA'
      AND cs.cs_sales_price > (SELECT AVG(cs_sales_price) FROM catalog_sales)
      AND i.i_current_price BETWEEN 20.00 AND 150.00
),
agg_data AS (
    SELECT
        c_customer_id,
        i_category,
        SUM(cs_ext_sales_price) AS total_sales_amount,
        SUM(cr_return_amount) AS total_return_amount,
        COUNT(DISTINCT cs_order_number) AS order_cnt,
        AVG(cs_sales_price) AS avg_sales_price,
        SUM(cr_fee) AS total_return_fee,
        GROUPING(c_customer_id) AS grp_cust,
        GROUPING(i_category) AS grp_cat
    FROM base_data
    GROUP BY ROLLUP (c_customer_id, i_category)
)
SELECT
    c_customer_id,
    i_category,
    total_sales_amount,
    total_return_amount,
    order_cnt,
    avg_sales_price,
    total_return_fee,
    ROW_NUMBER() OVER (PARTITION BY c_customer_id ORDER BY total_sales_amount DESC) AS sales_rank_by_customer,
    grp_cust,
    grp_cat
FROM agg_data
ORDER BY total_sales_amount DESC
LIMIT 100
