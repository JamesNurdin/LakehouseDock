WITH warehouse_returns AS (
   SELECT
      w.w_warehouse_sk,
      w.w_warehouse_name,
      w.w_city,
      w.w_state,
      w.w_warehouse_id,
      SUM(cr.cr_return_amount) AS total_return_amount,
      COUNT(*) AS return_cnt,
      SUM(cr.cr_store_credit) AS total_store_credit
   FROM
      tpcds.catalog_returns cr
   JOIN
      tpcds.warehouse w
      ON cr.cr_warehouse_sk = w.w_warehouse_sk
   WHERE
      regexp_like(w.w_city, '^[A-Z][a-z]+(?: [A-Z][a-z]+)*$')
      AND w.w_zip LIKE '6%'
   GROUP BY
      w.w_warehouse_sk,
      w.w_warehouse_name,
      w.w_city,
      w.w_state,
      w.w_warehouse_id
)

SELECT
   wr.w_warehouse_name,
   wr.w_city,
   wr.w_state,
   regexp_extract(wr.w_warehouse_id, '(\\d+)', 1) AS warehouse_id_num,
   wr.total_return_amount,
   wr.return_cnt,
   wr.total_store_credit,
   (wr.total_store_credit / nullif(wr.return_cnt, 0)) AS avg_store_credit,
   concat(wr.w_city, ', ', wr.w_state) AS city_state
FROM
   warehouse_returns wr
WHERE
   NOT EXISTS (
      SELECT 1
      FROM tpcds.catalog_returns cr2
      WHERE cr2.cr_warehouse_sk = wr.w_warehouse_sk
        AND cr2.cr_return_ship_cost > 1000
   )
   AND wr.total_return_amount > 5000
ORDER BY
   wr.total_return_amount DESC
LIMIT 100
