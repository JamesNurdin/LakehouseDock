WITH cat AS (
   SELECT i.i_item_id,
          i.i_product_name,
          r.r_reason_desc,
          SUM(cr.cr_return_quantity) AS total_qty,
          SUM(cr.cr_return_amount) AS total_amount
   FROM catalog_returns cr
   JOIN item i ON cr.cr_item_sk = i.i_item_sk
   JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
   WHERE cr.cr_return_amount > 500
   GROUP BY i.i_item_id, i.i_product_name, r.r_reason_desc
),
web AS (
   SELECT i.i_item_id,
          i.i_product_name,
          r.r_reason_desc,
          SUM(wr.wr_return_quantity) AS total_qty,
          SUM(wr.wr_return_amt) AS total_amount
   FROM web_returns wr
   JOIN item i ON wr.wr_item_sk = i.i_item_sk
   JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
   WHERE wr.wr_return_amt > 500
   GROUP BY i.i_item_id, i.i_product_name, r.r_reason_desc
),
unioned AS (
   SELECT i_item_id,
          i_product_name,
          r_reason_desc,
          total_qty,
          total_amount
   FROM cat
   UNION
   SELECT i_item_id,
          i_product_name,
          r_reason_desc,
          total_qty,
          total_amount
   FROM web
)
SELECT DISTINCT
       i_item_id,
       i_product_name,
       r_reason_desc,
       SUM(total_qty) AS total_return_quantity,
       SUM(total_amount) AS total_return_amount
FROM unioned
GROUP BY i_item_id, i_product_name, r_reason_desc
ORDER BY total_return_amount DESC
LIMIT 100
