WITH ton_returns AS (
   SELECT i.i_item_id,
          i.i_product_name,
          SUM(sr.sr_return_amt) AS total_return_amt,
          AVG(sr.sr_return_tax) AS avg_return_tax,
          cd.cd_gender
   FROM store_returns sr
   JOIN item i ON sr.sr_item_sk = i.i_item_sk
   JOIN customer_demographics cd ON sr.sr_cdemo_sk = cd.cd_demo_sk
   WHERE i.i_units = 'Ton'
     AND cd.cd_dep_count >= 2
     AND sr.sr_return_quantity > (
           SELECT AVG(sr2.sr_return_quantity)
           FROM store_returns sr2
           WHERE sr2.sr_item_sk = sr.sr_item_sk
         )
   GROUP BY i.i_item_id, i.i_product_name, cd.cd_gender
),

dozen_returns AS (
   SELECT i.i_item_id,
          i.i_product_name,
          SUM(sr.sr_return_amt) AS total_return_amt,
          AVG(sr.sr_return_tax) AS avg_return_tax,
          cd.cd_gender
   FROM store_returns sr
   JOIN item i ON sr.sr_item_sk = i.i_item_sk
   JOIN customer_demographics cd ON sr.sr_cdemo_sk = cd.cd_demo_sk
   WHERE i.i_units = 'Dozen'
     AND cd.cd_credit_rating = 'A'
     AND sr.sr_return_tax > 10
   GROUP BY i.i_item_id, i.i_product_name, cd.cd_gender
)
SELECT combined.i_item_id,
       combined.i_product_name,
       combined.total_return_amt,
       combined.avg_return_tax,
       combined.cd_gender
FROM (
   SELECT * FROM ton_returns
   UNION ALL
   SELECT * FROM dozen_returns
) AS combined
ORDER BY combined.total_return_amt DESC
LIMIT 100
