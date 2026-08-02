WITH sales_agg AS (
    SELECT
        i.i_brand AS brand,
        cd.cd_education_status AS education_status,
        cd.cd_credit_rating AS credit_rating,
        SUM(cs.cs_net_profit) AS total_net_profit,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        COUNT(*) AS sales_cnt
    FROM catalog_sales cs
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    WHERE cs.cs_quantity > 30
      AND cs.cs_list_price >= 50.00
      AND cd.cd_education_status IN ('College', 'Advanced Degree')
      AND cd.cd_credit_rating = 'Good'
    GROUP BY i.i_brand, cd.cd_education_status, cd.cd_credit_rating
),
returns_agg AS (
    SELECT
        i.i_brand AS brand,
        cd.cd_education_status AS education_status,
        cd.cd_credit_rating AS credit_rating,
        SUM(sr.sr_return_amt) AS total_return_amt,
        COUNT(*) AS return_cnt
    FROM store_returns sr
    LEFT JOIN item i ON sr.sr_item_sk = i.i_item_sk
    JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON sr.sr_cdemo_sk = cd.cd_demo_sk
    WHERE i.i_current_price > 20.00
      AND cd.cd_dep_employed_count <= 3
      AND c.c_last_review_date > 2452300
      AND EXISTS (
          SELECT 1
          FROM catalog_sales cs2
          WHERE cs2.cs_item_sk = sr.sr_item_sk
            AND cs2.cs_net_profit > 500
      )
    GROUP BY i.i_brand, cd.cd_education_status, cd.cd_credit_rating
)
SELECT
    combined.brand,
    combined.education_status,
    combined.credit_rating,
    combined.total_net_profit,
    combined.total_return_amt,
    combined.total_sales,
    combined.sales_cnt,
    combined.return_cnt,
    (combined.total_net_profit - COALESCE(combined.total_return_amt, 0)) AS net_profit_after_returns
FROM (
    SELECT
        s.brand,
        s.education_status,
        s.credit_rating,
        s.total_net_profit,
        r.total_return_amt,
        s.total_sales,
        s.sales_cnt,
        r.return_cnt
    FROM sales_agg s
    LEFT JOIN returns_agg r
        ON s.brand = r.brand
        AND s.education_status = r.education_status
        AND s.credit_rating = r.credit_rating

    UNION DISTINCT

    SELECT
        r.brand,
        r.education_status,
        r.credit_rating,
        0 AS total_net_profit,
        r.total_return_amt,
        0 AS total_sales,
        0 AS sales_cnt,
        r.return_cnt
    FROM returns_agg r
    WHERE r.total_return_amt > 100
) AS combined
WHERE (combined.total_net_profit - COALESCE(combined.total_return_amt, 0)) > 0
  AND combined.total_net_profit > (
      SELECT AVG(cs.cs_net_profit)
      FROM catalog_sales cs
      WHERE cs.cs_quantity > 30
  )
ORDER BY net_profit_after_returns DESC
LIMIT 100
