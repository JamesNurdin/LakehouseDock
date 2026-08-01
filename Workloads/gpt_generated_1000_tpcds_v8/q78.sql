WITH sales_data AS (
    SELECT
        cs.cs_sold_date_sk,
        cs.cs_order_number,
        cs.cs_item_sk,
        cs.cs_quantity,
        cs.cs_sales_price,
        cs.cs_net_paid,
        cp.cp_department,
        cp.cp_catalog_page_id,
        cd.cd_gender,
        d.d_year,
        d.d_date,
        st.s_store_id,
        st.s_state,
        sr.sr_return_amt_inc_tax,
        CASE WHEN cs.cs_net_paid > 1000 THEN 'High' ELSE 'Low' END AS sales_category
    FROM catalog_sales cs
    JOIN catalog_page cp
        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN customer_demographics cd
        ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN date_dim d
        ON cs.cs_sold_date_sk = d.d_date_sk
    LEFT JOIN store_returns sr
        ON sr.sr_returned_date_sk = d.d_date_sk
    LEFT JOIN store st
        ON sr.sr_store_sk = st.s_store_sk
    WHERE d.d_year = 1998
      AND st.s_state = 'CA'
      AND cp.cp_department = 'Books'
      AND cd.cd_gender = 'M'
      AND cs.cs_quantity > 5
      AND NOT EXISTS (
          SELECT 1
          FROM catalog_returns cr
          WHERE cr.cr_order_number = cs.cs_order_number
      )
)
SELECT
    d_year,
    cp_department,
    cd_gender,
    s_store_id,
    sales_category,
    COUNT(DISTINCT cs_order_number) AS num_orders,
    SUM(cs_net_paid) AS total_net_paid,
    AVG(cs_sales_price) AS avg_sales_price,
    SUM(sr_return_amt_inc_tax) AS total_return_inc_tax,
    MAX(cs_net_paid) AS max_net_paid,
    MIN(cs_net_paid) AS min_net_paid,
    ROW_NUMBER() OVER (PARTITION BY s_store_id ORDER BY SUM(cs_net_paid) DESC) AS store_sales_rank
FROM sales_data
GROUP BY
    d_year,
    cp_department,
    cd_gender,
    s_store_id,
    sales_category
HAVING SUM(cs_net_paid) > 5000
ORDER BY total_net_paid DESC
LIMIT 100
