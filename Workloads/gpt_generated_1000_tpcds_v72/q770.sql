WITH sales_agg AS (
    SELECT
        cc.cc_name AS call_center_name,
        cd.cd_gender AS gender,
        SUM(cs.cs_net_paid_inc_ship_tax) AS total_amount,
        'sales' AS source
    FROM catalog_sales cs
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    WHERE cs.cs_net_paid_inc_ship_tax > 5000
      AND EXISTS (
          SELECT 1
          FROM customer_demographics cd2
          WHERE cd2.cd_gender = cd.cd_gender
            AND cd2.cd_credit_rating = 'Excellent'
          LIMIT 1
      )
    GROUP BY ROLLUP (cc.cc_name, cd.cd_gender)
),
returns_agg AS (
    SELECT
        cc.cc_name AS call_center_name,
        cd.cd_gender AS gender,
        SUM(cr.cr_return_amount) AS total_amount,
        'returns' AS source
    FROM catalog_returns cr
    JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN customer_demographics cd ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
    WHERE cr.cr_return_amount > 1000
      AND cd.cd_credit_rating IN (
          SELECT DISTINCT cd3.cd_credit_rating
          FROM customer_demographics cd3
          WHERE cd3.cd_credit_rating IS NOT NULL
      )
    GROUP BY ROLLUP (cc.cc_name, cd.cd_gender)
)
SELECT DISTINCT *
FROM (
    SELECT * FROM sales_agg
    UNION ALL
    SELECT * FROM returns_agg
) combined
ORDER BY call_center_name, gender, source
LIMIT 100
