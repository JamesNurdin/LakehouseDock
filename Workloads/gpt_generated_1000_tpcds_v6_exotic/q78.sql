WITH item_promo_returns AS (
    SELECT 
        i.i_item_sk,
        i.i_product_name,
        i.i_brand,
        p.p_promo_name,
        sr.sr_returned_date_sk,
        SUM(sr.sr_return_amt) AS total_return_amt,
        SUM(sr.sr_return_quantity) AS total_return_qty,
        SUM(p.p_cost) AS total_promo_cost,
        SUM(inv.inv_quantity_on_hand) AS total_inventory_qty
    FROM store_returns sr
    JOIN item i
        ON sr.sr_item_sk = i.i_item_sk
    JOIN promotion p
        ON p.p_item_sk = i.i_item_sk
    JOIN inventory inv
        ON inv.inv_item_sk = i.i_item_sk
    WHERE sr.sr_returned_date_sk BETWEEN 2450900 AND 2451100
      AND inv.inv_date_sk BETWEEN 2450900 AND 2451100
      AND i.i_brand = 'Unknown'
      AND p.p_purpose = 'Unknown'
      AND p.p_response_target > 0
      AND inv.inv_warehouse_sk IN (1, 3, 4, 11, 15)
    GROUP BY i.i_item_sk, i.i_product_name, i.i_brand, p.p_promo_name, sr.sr_returned_date_sk
),
agg_item AS (
    SELECT
        i_item_sk,
        i_product_name,
        i_brand,
        SUM(total_return_amt) AS sum_return_amt,
        SUM(total_return_qty) AS sum_return_qty,
        SUM(total_promo_cost) AS sum_promo_cost,
        AVG(total_inventory_qty) AS avg_inventory_qty,
        COUNT(*) AS day_cnt
    FROM item_promo_returns
    GROUP BY i_item_sk, i_product_name, i_brand
    HAVING SUM(total_return_amt) > 1000
)
SELECT
    i_item_sk,
    i_product_name,
    i_brand,
    sum_return_amt,
    sum_return_qty,
    sum_promo_cost,
    avg_inventory_qty,
    day_cnt,
    RANK() OVER (ORDER BY sum_return_amt DESC) AS return_amt_rank,
    sum_return_amt / NULLIF(day_cnt, 0) AS avg_daily_return_amt
FROM agg_item
ORDER BY sum_return_amt DESC
LIMIT 100
