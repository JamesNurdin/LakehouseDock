WITH filtered_sales AS (
    SELECT
        ss.ss_cdemo_sk,
        ss.ss_net_profit,
        ss.ss_ext_discount_amt,
        ss.ss_quantity,
        ss.ss_ext_sales_price,
        ss.ss_net_paid_inc_tax
    FROM store_sales ss
    WHERE ss.ss_quantity > 0
      AND ss.ss_ext_sales_price > 0
)

SELECT
    cd.cd_education_status,
    cd.cd_gender,
    COUNT(*) AS num_transactions,
    SUM(fs.ss_net_profit) AS total_net_profit,
    AVG(fs.ss_ext_discount_amt) AS avg_discount_amt,
    SUM(fs.ss_ext_sales_price) / NULLIF(SUM(fs.ss_quantity), 0) AS avg_price_per_item,
    RANK() OVER (ORDER BY SUM(fs.ss_net_profit) DESC) AS profit_rank,
    (SELECT AVG(web_tax_percentage) FROM web_site) AS avg_web_tax_pct
FROM filtered_sales fs
JOIN customer_demographics cd
  ON fs.ss_cdemo_sk = cd.cd_demo_sk
WHERE cd.cd_credit_rating = 'Good'
  AND cd.cd_dep_employed_count > 0
GROUP BY cd.cd_education_status, cd.cd_gender
HAVING SUM(fs.ss_net_profit) > 1000
ORDER BY total_net_profit DESC
LIMIT 20
