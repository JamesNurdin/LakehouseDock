WITH filtered_sales AS (
    SELECT
        cs.cs_sold_date_sk,
        cs.cs_bill_cdemo_sk,
        cs.cs_net_paid_inc_tax,
        cs.cs_net_profit,
        cs.cs_coupon_amt,
        cs.cs_item_sk
    FROM tpcds.catalog_sales cs
    WHERE cs.cs_net_paid_inc_tax > 2000
      AND cs.cs_coupon_amt < 500
      AND EXISTS (
          SELECT 1
          FROM tpcds.catalog_sales cs2
          WHERE cs2.cs_item_sk = cs.cs_item_sk
            AND cs2.cs_net_paid_inc_tax > 3000
      )
),
agg_sales AS (
    SELECT
        d.d_quarter_name,
        cd.cd_gender,
        SUM(fs.cs_net_paid_inc_tax) AS total_net_paid,
        SUM(fs.cs_net_profit) AS total_profit,
        COUNT(*) AS sales_cnt
    FROM filtered_sales fs
    JOIN tpcds.date_dim d
      ON fs.cs_sold_date_sk = d.d_date_sk
    JOIN tpcds.customer_demographics cd
      ON fs.cs_bill_cdemo_sk = cd.cd_demo_sk
    WHERE d.d_quarter_name IN ('1900Q3', '1901Q3')
      AND cd.cd_gender = 'F'
    GROUP BY ROLLUP (d.d_quarter_name, cd.cd_gender)
)
SELECT
    d_quarter_name,
    cd_gender,
    total_net_paid,
    total_profit,
    sales_cnt,
    RANK() OVER (PARTITION BY d_quarter_name ORDER BY total_net_paid DESC) AS rank_by_net_paid,
    CASE
        WHEN total_net_paid > (
            SELECT AVG(cs.cs_net_paid_inc_tax)
            FROM tpcds.catalog_sales cs
        ) THEN 'Above Avg'
        ELSE 'Below Avg'
    END AS performance_category
FROM agg_sales
ORDER BY d_quarter_name, cd_gender NULLS LAST
