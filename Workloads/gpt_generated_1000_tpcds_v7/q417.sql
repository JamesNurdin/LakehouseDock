WITH filtered AS (
        SELECT cr_warehouse_sk,
               cr_return_amount,
               cr_net_loss,
               cr_return_quantity,
               cr_return_tax,
               cr_refunded_cash
        FROM tpcds.catalog_returns
        WHERE cr_return_tax > 10.00
          AND cr_refunded_cash >= 100.00
          AND cr_return_quantity > 1
          AND cr_return_amount > 0.00
      ),
      joined AS (
        SELECT f.cr_warehouse_sk,
               f.cr_return_amount,
               f.cr_net_loss,
               w.w_warehouse_name,
               w.w_city,
               w.w_state
        FROM filtered f
        JOIN tpcds.warehouse w
          ON f.cr_warehouse_sk = w.w_warehouse_sk
        WHERE w.w_state = 'CA'
          AND w.w_city = 'San Jose'
      ),
      agg AS (
        SELECT w_warehouse_name,
               w_city,
               w_state,
               SUM(cr_return_amount) AS total_return_amount,
               SUM(cr_net_loss)      AS total_net_loss
        FROM joined
        GROUP BY w_warehouse_name, w_city, w_state
      )
SELECT w_warehouse_name,
       w_city,
       w_state,
       total_return_amount,
       total_net_loss,
       CASE WHEN total_net_loss > 1000 THEN 'High' ELSE 'Low' END AS loss_category,
       ROW_NUMBER() OVER (ORDER BY total_net_loss DESC) AS loss_rank,
       RANK()       OVER (ORDER BY total_return_amount DESC) AS return_amount_rank
FROM agg
ORDER BY total_net_loss DESC
LIMIT 10
