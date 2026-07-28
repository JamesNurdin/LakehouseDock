WITH joined_data AS (
   SELECT
       s.s_store_id,
       s.s_market_id,
       s.s_tax_percentage,
       c.c_customer_id,
       cp.cp_department,
       cr.cr_return_quantity,
       cr.cr_net_loss AS catalog_net_loss,
       sr.sr_net_loss AS store_net_loss
   FROM store s
   JOIN store_returns sr
     ON sr.sr_store_sk = s.s_store_sk
   JOIN customer c
     ON c.c_customer_sk = sr.sr_customer_sk
   JOIN catalog_returns cr
     ON cr.cr_refunded_customer_sk = c.c_customer_sk
   JOIN catalog_page cp
     ON cp.cp_catalog_page_sk = cr.cr_catalog_page_sk
   WHERE s.s_street_type IN ('Court', 'Drive')
     AND cr.cr_return_quantity > 10
     AND s.s_tax_percentage > 5.0
),
agg_by_store_dept AS (
   SELECT
       s_store_id,
       s_market_id,
       cp_department,
       COUNT(*) AS txn_count,
       SUM(catalog_net_loss + store_net_loss) AS total_net_loss,
       SUM(cr_return_quantity) AS total_return_qty,
       AVG(cr_return_quantity) AS avg_return_qty
   FROM joined_data
   GROUP BY s_store_id, s_market_id, cp_department
)
SELECT
    s_store_id,
    s_market_id,
    cp_department,
    txn_count,
    total_net_loss,
    (SELECT AVG(total_net_loss) FROM agg_by_store_dept) AS avg_total_loss,
    RANK() OVER (ORDER BY total_net_loss DESC) AS loss_rank,
    SUM(total_net_loss) OVER (PARTITION BY s_market_id ORDER BY total_net_loss DESC ROWS UNBOUNDED PRECEDING) AS cumulative_loss
FROM agg_by_store_dept
WHERE total_net_loss > (SELECT AVG(total_net_loss) FROM agg_by_store_dept)
ORDER BY total_net_loss DESC
LIMIT 100
