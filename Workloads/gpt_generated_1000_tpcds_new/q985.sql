WITH deep_join AS (
   SELECT
        cr.cr_order_number,
        cr.cr_return_amount,
        cr.cr_return_quantity,
        i1.i_product_name AS product_name,
        sm1.sm_type AS ship_type,
        w1.w_warehouse_name AS warehouse_name,
        wr1.wr_return_amt AS web_ret_amt1,
        wr2.wr_return_amt AS web_ret_amt2,
        wr3.wr_return_amt AS web_ret_amt3
   FROM catalog_returns cr
   JOIN item i1 ON cr.cr_item_sk = i1.i_item_sk
   JOIN item i2 ON cr.cr_item_sk = i2.i_item_sk
   JOIN ship_mode sm1 ON cr.cr_ship_mode_sk = sm1.sm_ship_mode_sk
   JOIN ship_mode sm2 ON cr.cr_ship_mode_sk = sm2.sm_ship_mode_sk
   JOIN warehouse w1 ON cr.cr_warehouse_sk = w1.w_warehouse_sk
   JOIN warehouse w2 ON cr.cr_warehouse_sk = w2.w_warehouse_sk
   JOIN web_returns wr1 ON wr1.wr_item_sk = i1.i_item_sk
   JOIN web_returns wr2 ON wr2.wr_item_sk = i2.i_item_sk
   JOIN web_returns wr3 ON wr3.wr_item_sk = i1.i_item_sk
   WHERE cr.cr_return_amount > 5
),

sampled AS (
   SELECT *
   FROM deep_join
   TABLESAMPLE BERNOULLI (10)  -- sample 10% of rows
),

union_src AS (
   SELECT cr.cr_order_number AS order_num,
          cr.cr_return_amount AS ret_amount,
          cr.cr_return_quantity AS ret_qty,
          i.i_product_name AS prod_name,
          'catalog' AS src
   FROM catalog_returns cr
   JOIN item i ON cr.cr_item_sk = i.i_item_sk
   UNION DISTINCT
   SELECT wr.wr_order_number AS order_num,
          wr.wr_return_amt AS ret_amount,
          wr.wr_return_quantity AS ret_qty,
          i2.i_product_name AS prod_name,
          'web' AS src
   FROM web_returns wr
   JOIN item i2 ON wr.wr_item_sk = i2.i_item_sk
),

high_catalog AS (
   SELECT cr_order_number AS order_num
   FROM catalog_returns
   WHERE cr_return_amount > 20
),

high_web AS (
   SELECT wr_order_number AS order_num
   FROM web_returns
   WHERE wr_return_amt > 30
),

intersect_orders AS (
   SELECT order_num FROM high_catalog
   INTERSECT
   SELECT order_num FROM high_web
),

final AS (
   SELECT
        s.order_num,
        s.ret_amount,
        s.ret_qty,
        s.prod_name,
        s.src,
        SUM(s.ret_amount) OVER (PARTITION BY s.src ORDER BY s.ret_amount DESC ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS running_total,
        LAG(s.ret_qty) OVER (PARTITION BY s.src ORDER BY s.ret_amount) AS prev_qty,
        CASE WHEN s.order_num IN (SELECT order_num FROM intersect_orders) THEN 1 ELSE 0 END AS in_intersect
   FROM union_src s
   WHERE EXISTS (
        SELECT 1
        FROM sampled d
        WHERE d.cr_order_number = s.order_num
          AND d.product_name = s.prod_name
   )
)
SELECT
    order_num,
    ret_amount,
    ret_qty,
    prod_name,
    src,
    running_total,
    prev_qty,
    in_intersect
FROM final
ORDER BY running_total DESC
LIMIT 100
