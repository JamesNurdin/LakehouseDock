WITH wr_agg AS (
    SELECT
        wr_item_sk,
        SUM(wr_return_amt) AS total_return_amt,
        COUNT(*) AS return_cnt
    FROM web_returns
    WHERE wr_returned_date_sk BETWEEN 2450800 AND 2450900
      AND wr_return_amt IS NOT NULL
    GROUP BY wr_item_sk
)
SELECT
    i.i_item_id,
    i.i_product_name,
    i.i_brand,
    i.i_category,
    cc.cc_name AS call_center_name,
    c.c_customer_id,
    cd.cd_gender,
    SUM(cs.cs_ext_sales_price) AS total_sales,
    wr_agg.total_return_amt,
    RANK() OVER (PARTITION BY i.i_brand ORDER BY wr_agg.total_return_amt DESC) AS brand_return_rank,
    ROW_NUMBER() OVER (ORDER BY SUM(cs.cs_ext_sales_price) DESC) AS overall_sales_rank
FROM catalog_sales cs
INNER JOIN customer c
    ON cs.cs_bill_customer_sk = c.c_customer_sk
INNER JOIN customer_demographics cd
    ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
INNER JOIN item i
    ON cs.cs_item_sk = i.i_item_sk
INNER JOIN call_center cc
    ON cs.cs_call_center_sk = cc.cc_call_center_sk
LEFT JOIN wr_agg
    ON i.i_item_sk = wr_agg.wr_item_sk
WHERE cs.cs_sold_date_sk BETWEEN 2450820 AND 2450835
  AND c.c_birth_month IN (5, 9, 6)
  AND c.c_birth_country = 'URUGUAY'
  AND cc.cc_state = 'CA'
  AND i.i_brand = 'Brand#12'
GROUP BY
    i.i_item_id,
    i.i_product_name,
    i.i_brand,
    i.i_category,
    cc.cc_name,
    c.c_customer_id,
    cd.cd_gender,
    wr_agg.total_return_amt
ORDER BY overall_sales_rank
LIMIT 100
