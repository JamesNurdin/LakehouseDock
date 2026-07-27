WITH cs AS (
   SELECT
       cs.cs_bill_cdemo_sk,
       cs.cs_ext_sales_price,
       cs.cs_net_profit
   FROM catalog_sales cs
   WHERE cs.cs_quantity > 0
),
wr AS (
   SELECT
       wr.wr_returning_cdemo_sk,
       wr.wr_net_loss,
       wr.wr_return_amt
   FROM web_returns wr
   WHERE wr.wr_return_quantity > 0
),
cd AS (
   SELECT
       cd.cd_demo_sk,
       cd.cd_credit_rating,
       cd.cd_marital_status,
       cd.cd_gender
   FROM customer_demographics cd
   WHERE regexp_like(cd.cd_credit_rating, '^A[0-9]{2}$')
     AND cd.cd_marital_status LIKE 'S%'
)
SELECT
   concat('Rating ', cd.cd_credit_rating) AS rating_desc,
   cd.cd_marital_status,
   cd.cd_gender,
   SUM(cs.cs_ext_sales_price) AS total_sales,
   SUM(cs.cs_net_profit) AS total_profit,
   SUM(wr.wr_net_loss) AS total_return_loss,
   COUNT(DISTINCT cs.cs_bill_cdemo_sk) AS num_customers,
   regexp_extract(cd.cd_credit_rating, '([0-9]+)') AS rating_number
FROM cd
LEFT JOIN cs ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
LEFT JOIN wr ON wr.wr_returning_cdemo_sk = cd.cd_demo_sk
GROUP BY
   concat('Rating ', cd.cd_credit_rating),
   cd.cd_marital_status,
   cd.cd_gender,
   regexp_extract(cd.cd_credit_rating, '([0-9]+)')
ORDER BY total_sales DESC
LIMIT 100
