WITH base AS (
    SELECT
        sr.sr_store_sk,
        i.i_item_sk,
        i.i_product_name,
        i.i_current_price,
        r.r_reason_desc,
        t.t_shift,
        t.t_hour,
        SUM(sr.sr_return_amt) AS total_return_amt,
        SUM(sr.sr_return_quantity) AS total_return_qty,
        SUM(sr.sr_net_loss) AS total_net_loss,
        COUNT(*) AS return_count,
        AVG(p.p_cost) AS avg_promo_cost,
        MAX(inv.inv_quantity_on_hand) AS max_qty_on_hand,
        MIN(inv.inv_quantity_on_hand) AS min_qty_on_hand
    FROM store_returns sr
    JOIN time_dim t ON sr.sr_return_time_sk = t.t_time_sk
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk
    JOIN promotion p ON p.p_item_sk = i.i_item_sk
    WHERE t.t_shift = 'first'
      AND t.t_hour BETWEEN 8 AND 17
      AND sr.sr_return_amt > 20.00
      AND p.p_cost > 500.00
      AND inv.inv_quantity_on_hand > 0
      AND i.i_current_price < 100.00
    GROUP BY sr.sr_store_sk, i.i_item_sk, i.i_product_name, i.i_current_price,
             r.r_reason_desc, t.t_shift, t.t_hour
)
SELECT
    base.sr_store_sk,
    base.t_shift,
    COUNT(DISTINCT base.i_item_sk) AS distinct_items_sold,
    SUM(base.total_return_amt) AS store_total_return_amt,
    AVG(base.total_net_loss) AS avg_item_net_loss,
    SUM(base.avg_promo_cost) AS store_total_avg_promo_cost
FROM base
GROUP BY base.sr_store_sk, base.t_shift
HAVING SUM(base.total_return_amt) > 500.00
   AND COUNT(DISTINCT base.i_item_sk) >= 3
ORDER BY store_total_return_amt DESC
LIMIT 100
