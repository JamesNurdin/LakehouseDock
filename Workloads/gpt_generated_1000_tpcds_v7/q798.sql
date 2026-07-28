WITH sales_by_dept AS (
    SELECT
        'catalog_sales' AS source,
        cp.cp_department AS category,
        SUM(cs.cs_ext_sales_price) AS amount
    FROM catalog_sales cs
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    WHERE p.p_channel_details LIKE '%common%'
      AND EXISTS (
          SELECT 1
          FROM customer_demographics cd
          WHERE cd.cd_demo_sk = cs.cs_bill_cdemo_sk
            AND cd.cd_credit_rating = 'High Risk'
      )
    GROUP BY cp.cp_department
),
returns_by_reason AS (
    SELECT
        'web_returns' AS source,
        r.r_reason_desc AS category,
        SUM(wr.wr_net_loss) AS amount
    FROM web_returns wr
    JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
    WHERE r.r_reason_id LIKE 'AAAAAAA%'
    GROUP BY r.r_reason_desc
)
SELECT source, category, amount
FROM sales_by_dept
UNION ALL
SELECT source, category, amount
FROM returns_by_reason
ORDER BY amount DESC
