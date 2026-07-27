WITH returns_by_amount AS (
   SELECT
       i.i_item_id,
       i.i_product_name,
       wr.wr_return_amt AS return_metric,
       ROW_NUMBER() OVER (PARTITION BY i.i_brand ORDER BY wr.wr_return_amt DESC) AS brand_return_rank
   FROM tpcds.web_returns wr
   JOIN tpcds.item i ON wr.wr_item_sk = i.i_item_sk
   WHERE wr.wr_return_amt > 150.00
     AND i.i_category = 'Electronics'
),
returns_by_tax AS (
   SELECT DISTINCT
       i.i_item_id,
       i.i_product_name,
       wr.wr_return_tax AS return_metric,
       CAST(NULL AS bigint) AS brand_return_rank
   FROM tpcds.web_returns wr
   JOIN tpcds.item i ON wr.wr_item_sk = i.i_item_sk
   WHERE wr.wr_return_tax > 20.00
     AND i.i_brand = 'Brand#12'
)
SELECT *
FROM (
   SELECT * FROM returns_by_amount
   UNION ALL
   SELECT * FROM returns_by_tax
) combined
ORDER BY return_metric DESC
LIMIT 100
