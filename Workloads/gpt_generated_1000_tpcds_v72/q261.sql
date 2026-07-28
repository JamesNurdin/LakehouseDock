WITH base AS (
   SELECT
       cr.cr_returned_date_sk,
       d.d_year,
       d.d_month_seq,
       ca_refunded.ca_state AS refunded_state,
       promo.p_promo_name,
       cr.cr_return_amount,
       cr.cr_return_amt_inc_tax,
       cr.cr_net_loss,
       cr.cr_return_quantity
   FROM catalog_returns cr
   JOIN date_dim d
     ON cr.cr_returned_date_sk = d.d_date_sk
   JOIN time_dim t
     ON cr.cr_returned_time_sk = t.t_time_sk
   JOIN customer c_refunded
     ON cr.cr_refunded_customer_sk = c_refunded.c_customer_sk
   JOIN customer_address ca_refunded
     ON cr.cr_refunded_addr_sk = ca_refunded.ca_address_sk
   -- joining the returning side (required by the join rules, even if not used later)
   JOIN customer c_returning
     ON cr.cr_returning_customer_sk = c_returning.c_customer_sk
   LEFT JOIN promotion promo
     ON d.d_date_sk = promo.p_start_date_sk
   LEFT JOIN inventory inv
     ON d.d_date_sk = inv.inv_date_sk
   WHERE d.d_year = 2001
     AND t.t_hour BETWEEN 9 AND 17
     AND (inv.inv_quantity_on_hand > 500 OR inv.inv_quantity_on_hand IS NULL)
)
SELECT
    agg.d_year,
    agg.d_month_seq,
    agg.refunded_state,
    agg.p_promo_name,
    agg.total_return_amount,
    agg.avg_return_amount,
    agg.return_cnt,
    agg.max_net_loss,
    overall.avg_return_amount_overall,
    ROW_NUMBER() OVER (PARTITION BY agg.d_year ORDER BY agg.total_return_amount DESC) AS rn
FROM (
    SELECT
        b.d_year,
        b.d_month_seq,
        b.refunded_state,
        b.p_promo_name,
        SUM(b.cr_return_amount) AS total_return_amount,
        AVG(b.cr_return_amount) AS avg_return_amount,
        COUNT(*) AS return_cnt,
        MAX(b.cr_net_loss) AS max_net_loss
    FROM base b
    WHERE EXISTS (
        SELECT 1 FROM promotion p
        WHERE p.p_start_date_sk = b.cr_returned_date_sk
          AND p.p_discount_active = 'Y'
    )
    GROUP BY b.d_year, b.d_month_seq, b.refunded_state, b.p_promo_name
) agg
CROSS JOIN (
    SELECT AVG(cr_return_amount) AS avg_return_amount_overall
    FROM catalog_returns
) overall
ORDER BY agg.total_return_amount DESC, agg.d_year
LIMIT 100
