WITH joined_data AS (
   SELECT
       dd.d_year,
       dd.d_month_seq,
       w.w_warehouse_name,
       w.w_state,
       i.i_category,
       i.i_class,
       i.i_size,
       i.i_brand,
       p.p_promo_name,
       r.r_reason_desc,
       sr.sr_return_amt,
       sr.sr_net_loss,
       inv.inv_quantity_on_hand,
       p.p_cost AS promo_cost
   FROM store_returns sr
   JOIN date_dim dd ON sr.sr_returned_date_sk = dd.d_date_sk
   JOIN item i ON sr.sr_item_sk = i.i_item_sk
   JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
   JOIN inventory inv ON inv.inv_date_sk = dd.d_date_sk
                     AND inv.inv_item_sk = i.i_item_sk
   JOIN warehouse w ON inv.inv_warehouse_sk = w.w_warehouse_sk
   LEFT JOIN promotion p ON p.p_item_sk = i.i_item_sk
                         AND p.p_start_date_sk = dd.d_date_sk
   WHERE dd.d_date BETWEEN DATE '2000-01-01' AND DATE '2000-12-31'
     AND i.i_size IN ('small', 'large')
     AND w.w_state = 'CA'
),
agg AS (
   SELECT
       d_year,
       d_month_seq,
       w_warehouse_name,
       i_category,
       i_class,
       SUM(sr_return_amt) AS total_return_amt,
       SUM(sr_net_loss) AS total_net_loss,
       SUM(inv_quantity_on_hand) AS total_inventory,
       SUM(promo_cost) AS total_promo_cost
   FROM joined_data
   GROUP BY d_year, d_month_seq, w_warehouse_name, i_category, i_class
   HAVING SUM(sr_net_loss) > 1000
)
SELECT
   d_year,
   d_month_seq,
   w_warehouse_name,
   i_category,
   i_class,
   total_return_amt,
   total_net_loss,
   total_inventory,
   total_promo_cost,
   RANK() OVER (PARTITION BY d_year ORDER BY total_net_loss DESC) AS net_loss_rank
FROM agg
ORDER BY d_year DESC, net_loss_rank
LIMIT 100
