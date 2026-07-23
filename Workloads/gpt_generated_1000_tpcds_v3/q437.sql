WITH base AS (
    SELECT
        i.i_item_id AS item_id,
        i.i_product_name AS product_name,
        w.w_warehouse_name AS warehouse_name,
        d_wr.d_date AS return_date,
        SUM(wr.wr_return_quantity) AS total_return_qty,
        SUM(wr.wr_net_loss) AS total_net_loss,
        SUM(inv.inv_quantity_on_hand) AS total_on_hand,
        SUM(CASE
                WHEN p.p_promo_sk IS NOT NULL
                     AND d_wr.d_date BETWEEN d_promo_start.d_date AND d_promo_end.d_date
                     AND p.p_discount_active = 'Y'
                THEN p.p_cost
                ELSE 0
            END) AS promo_cost_active,
        SUM(CASE
                WHEN p.p_promo_sk IS NOT NULL
                     AND d_wr.d_date BETWEEN d_promo_start.d_date AND d_promo_end.d_date
                THEN 1
                ELSE 0
            END) AS active_promo_cnt
    FROM web_returns wr
    JOIN date_dim d_wr
        ON wr.wr_returned_date_sk = d_wr.d_date_sk
    JOIN item i
        ON wr.wr_item_sk = i.i_item_sk
    JOIN inventory inv
        ON inv.inv_item_sk = i.i_item_sk
       AND inv.inv_date_sk = d_wr.d_date_sk
    JOIN warehouse w
        ON inv.inv_warehouse_sk = w.w_warehouse_sk
    LEFT JOIN promotion p
        ON p.p_item_sk = i.i_item_sk
    LEFT JOIN date_dim d_promo_start
        ON p.p_start_date_sk = d_promo_start.d_date_sk
    LEFT JOIN date_dim d_promo_end
        ON p.p_end_date_sk = d_promo_end.d_date_sk
    WHERE d_wr.d_date BETWEEN DATE '2020-01-01' AND DATE '2020-12-31'
      AND i.i_units = 'Pallet'
      AND w.w_state = 'CA'
      AND i.i_current_price > 20
    GROUP BY i.i_item_id, i.i_product_name, w.w_warehouse_name, d_wr.d_date
)
SELECT
    item_id,
    product_name,
    SUM(total_return_qty) AS total_return_quantity,
    AVG(total_net_loss) AS avg_daily_net_loss,
    SUM(total_on_hand) AS total_on_hand_quantity,
    SUM(promo_cost_active) AS total_active_promo_cost,
    SUM(active_promo_cnt) AS total_active_promo_count
FROM base
GROUP BY item_id, product_name
HAVING AVG(total_net_loss) > 500
ORDER BY avg_daily_net_loss DESC
LIMIT 100
