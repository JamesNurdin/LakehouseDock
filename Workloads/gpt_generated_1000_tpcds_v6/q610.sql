WITH sales_by_demo AS (
    SELECT
        cs_bill_cdemo_sk AS demo_sk,
        SUM(cs_net_paid)          AS total_net_paid,
        SUM(cs_ext_sales_price)   AS total_ext_sales,
        COUNT(*)                  AS sales_cnt,
        MAX(cs_coupon_amt)        AS max_coupon_amt
    FROM catalog_sales
    WHERE cs_coupon_amt > 0
    GROUP BY cs_bill_cdemo_sk
)
SELECT
    cd.cd_demo_sk,
    cd.cd_gender,
    cd.cd_credit_rating,
    sb.total_net_paid,
    sb.total_ext_sales,
    sb.sales_cnt,
    -- extract the word before "Risk" if present (e.g., "High" from "High Risk")
    regexp_extract(cd.cd_credit_rating, '(\\w+) Risk', 1) AS risk_level,
    -- first four characters of the credit rating string
    substr(cd.cd_credit_rating, 1, 4)                     AS rating_prefix,
    -- build a readable demo identifier
    concat('Demo_', cast(cd.cd_demo_sk as varchar))      AS demo_id,
    -- scalar subquery: average net paid for this demographic across all sales
    (SELECT AVG(cs_net_paid)
     FROM catalog_sales
     WHERE cs_bill_cdemo_sk = cd.cd_demo_sk)           AS avg_net_paid,
    -- rank customers of the same gender by total net paid
    rank() OVER (PARTITION BY cd.cd_gender ORDER BY sb.total_net_paid DESC) AS gender_rank
FROM sales_by_demo sb
JOIN customer_demographics cd
    ON sb.demo_sk = cd.cd_demo_sk
WHERE
    -- keep only rows where the credit rating mentions Risk or Good
    regexp_like(cd.cd_credit_rating, 'Risk|Good')
    AND cd.cd_credit_rating LIKE '%Risk%'
    AND cd.cd_gender LIKE 'F%'
ORDER BY
    sb.total_net_paid DESC,
    gender_rank ASC
LIMIT 100
