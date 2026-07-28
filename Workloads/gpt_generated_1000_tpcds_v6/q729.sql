WITH sales_agg AS (
    SELECT
        cs_item_sk,
        cs_sold_date_sk,
        cs_bill_cdemo_sk,
        SUM(cs_net_paid) AS total_net_paid,
        SUM(cs_quantity) AS total_quantity,
        COUNT(*) AS sales_cnt,
        AVG(cs_ext_discount_amt) AS avg_discount
    FROM catalog_sales
    WHERE cs_quantity > 0
    GROUP BY cs_item_sk, cs_sold_date_sk, cs_bill_cdemo_sk
)
SELECT
    i.i_item_id,
    i.i_product_name,
    d_sold.d_year,
    d_sold.d_month_seq,
    s.s_store_name,
    s.s_state,
    sa.total_net_paid,
    sa.total_quantity,
    sa.sales_cnt,
    sa.avg_discount,
    ROW_NUMBER() OVER (PARTITION BY i.i_item_id ORDER BY sa.total_net_paid DESC) AS rn_item_net_paid,
    MAX(sa.total_net_paid) OVER (PARTITION BY d_sold.d_year) AS max_year_net_paid
FROM sales_agg sa
JOIN item i
    ON sa.cs_item_sk = i.i_item_sk
JOIN date_dim d_sold
    ON sa.cs_sold_date_sk = d_sold.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = d_sold.d_date_sk
JOIN customer_demographics cd
    ON sa.cs_bill_cdemo_sk = cd.cd_demo_sk
WHERE i.i_class_id IN (1, 6, 9)
  AND i.i_rec_start_date BETWEEN DATE '2000-01-01' AND DATE '2001-12-31'
  AND d_sold.d_weekend = 'N'
  AND d_sold.d_year = 2001
  AND cd.cd_credit_rating = 'Good'
  AND cd.cd_dep_college_count >= 2
  AND s.s_state = 'CA'
  AND NOT EXISTS (
        SELECT 1
        FROM catalog_sales cs2
        WHERE cs2.cs_item_sk = i.i_item_sk
          AND cs2.cs_net_profit < 0
    )
ORDER BY sa.total_net_paid DESC
LIMIT 100
