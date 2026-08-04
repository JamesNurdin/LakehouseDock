WITH sales_agg AS (
    SELECT
        cs_sold_date_sk,
        cs_ship_mode_sk,
        cs_bill_cdemo_sk,
        SUM(cs_net_paid) AS sum_net_paid,
        AVG(cs_quantity) AS avg_quantity,
        COUNT(*) AS sales_cnt
    FROM catalog_sales
    WHERE cs_quantity > 2
      AND cs_net_paid > 0
      AND cs_ext_discount_amt > 0
    GROUP BY cs_sold_date_sk, cs_ship_mode_sk, cs_bill_cdemo_sk
)
SELECT
    d.d_year,
    d.d_month_seq,
    sm.sm_carrier,
    cd.cd_gender,
    wp.wp_type,
    sa.sum_net_paid,
    sa.avg_quantity,
    sa.sales_cnt,
    ROW_NUMBER() OVER (PARTITION BY d.d_year ORDER BY sa.sum_net_paid DESC) AS rn
FROM sales_agg sa
JOIN date_dim d
    ON sa.cs_sold_date_sk = d.d_date_sk
JOIN ship_mode sm
    ON sa.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN customer_demographics cd
    ON sa.cs_bill_cdemo_sk = cd.cd_demo_sk
JOIN web_page wp
    ON wp.wp_creation_date_sk = d.d_date_sk
WHERE d.d_dom IN (3, 10, 19)
  AND d.d_dow = 5
  AND sm.sm_carrier = 'GREAT EASTERN'
  AND wp.wp_autogen_flag = 'N'
  AND cd.cd_gender = 'M'
  AND d.d_date BETWEEN DATE '1998-01-01' AND DATE '1998-12-31'
  AND sa.cs_sold_date_sk NOT IN (
        SELECT cs_sold_date_sk FROM catalog_sales WHERE cs_quantity = 0
    )
ORDER BY d.d_year, rn
