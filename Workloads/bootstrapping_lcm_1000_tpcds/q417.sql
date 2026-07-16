WITH inv_agg AS (
    SELECT inv_date_sk,
           SUM(inv_quantity_on_hand) AS total_qty_on_hand
    FROM inventory
    GROUP BY inv_date_sk
),
promo_agg AS (
    SELECT d.d_date_sk AS d_date_sk,
           SUM(COALESCE(p_start.p_cost, 0)) + SUM(COALESCE(p_end.p_cost, 0)) AS total_promo_cost,
           COUNT(DISTINCT p_start.p_promo_id) + COUNT(DISTINCT p_end.p_promo_id) AS promo_count
    FROM date_dim d
    LEFT JOIN promotion p_start ON p_start.p_start_date_sk = d.d_date_sk
    LEFT JOIN promotion p_end   ON p_end.p_end_date_sk   = d.d_date_sk
    GROUP BY d.d_date_sk
),
returns_agg AS (
    SELECT
        s.s_store_id,
        s.s_city,
        dd.d_year,
        COUNT(DISTINCT cr.cr_order_number) AS num_returns,
        SUM(cr.cr_return_amount)          AS total_return_amount,
        SUM(cr.cr_net_loss)               AS total_net_loss,
        ia.total_qty_on_hand,
        pa.total_promo_cost,
        pa.promo_count
    FROM catalog_returns cr
    JOIN date_dim dd ON cr.cr_returned_date_sk = dd.d_date_sk
    LEFT JOIN store s ON s.s_closed_date_sk = dd.d_date_sk
    LEFT JOIN inv_agg ia ON ia.inv_date_sk = dd.d_date_sk
    LEFT JOIN promo_agg pa ON pa.d_date_sk = dd.d_date_sk
    WHERE dd.d_year BETWEEN 2015 AND 2020
    GROUP BY s.s_store_id, s.s_city, dd.d_year, ia.total_qty_on_hand, pa.total_promo_cost, pa.promo_count
)
SELECT
    s_store_id,
    s_city,
    d_year,
    num_returns,
    total_return_amount,
    total_net_loss,
    total_qty_on_hand,
    total_promo_cost,
    promo_count,
    ROW_NUMBER() OVER (PARTITION BY d_year ORDER BY total_net_loss DESC) AS net_loss_rank
FROM returns_agg
ORDER BY total_net_loss DESC
LIMIT 100
