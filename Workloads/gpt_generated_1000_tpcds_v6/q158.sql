WITH agg AS (
    SELECT
        d_ret.d_year,
        inv.inv_item_sk,
        p.p_promo_name,
        SUM(sr.sr_return_amt) AS total_return_amt,
        SUM(sr.sr_return_quantity) AS total_return_qty
    FROM store_returns sr
    JOIN date_dim d_ret
        ON sr.sr_returned_date_sk = d_ret.d_date_sk
    JOIN inventory inv
        ON inv.inv_date_sk = d_ret.d_date_sk
    JOIN promotion p
        ON p.p_start_date_sk = d_ret.d_date_sk
    WHERE d_ret.d_year = 2001                      -- filter by calendar year
      AND inv.inv_quantity_on_hand > 500          -- keep well‑stocked items
      AND inv.inv_warehouse_sk IN (1, 5)           -- restrict to two warehouses
      AND p.p_channel_tv = 'N'                    -- TV channel not used
      AND p.p_discount_active = 'Y'               -- only active discounts
    GROUP BY d_ret.d_year, inv.inv_item_sk, p.p_promo_name
)
SELECT
    d_year,
    inv_item_sk,
    p_promo_name,
    total_return_amt,
    total_return_qty,
    RANK() OVER (PARTITION BY d_year ORDER BY total_return_amt DESC) AS return_amt_rank
FROM agg
ORDER BY d_year, return_amt_rank
LIMIT 100
