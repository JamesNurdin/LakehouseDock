WITH inv_agg AS (
    SELECT
        inv_item_sk,
        inv_warehouse_sk,
        SUM(inv_quantity_on_hand) AS total_qty_on_hand
    FROM inventory
    GROUP BY inv_item_sk, inv_warehouse_sk
)
SELECT DISTINCT
    sr.sr_ticket_number,
    i.i_item_id,
    i.i_product_name,
    w.w_warehouse_id,
    w.w_warehouse_name,
    w.w_warehouse_sq_ft,
    cd.cd_education_status,
    hd.hd_buy_potential,
    ib.ib_lower_bound,
    inv_agg.total_qty_on_hand,
    sr.sr_return_amt_inc_tax,
    CASE
        WHEN w.w_warehouse_sq_ft > 750000 THEN 'Large'
        WHEN w.w_warehouse_sq_ft > 500000 THEN 'Medium'
        ELSE 'Small'
    END AS warehouse_size_category,
    (SELECT SUM(sr2.sr_return_quantity)
     FROM store_returns sr2
     WHERE sr2.sr_item_sk = i.i_item_sk) AS total_returns_for_item,
    RANK() OVER (PARTITION BY w.w_warehouse_id ORDER BY sr.sr_return_amt_inc_tax DESC) AS return_amt_rank,
    CASE
        WHEN sr.sr_return_amt_inc_tax > (SELECT AVG(sr3.sr_return_amt_inc_tax) FROM store_returns sr3) THEN 'Above Avg'
        ELSE 'Below Avg'
    END AS return_vs_avg
FROM store_returns sr
JOIN item i ON sr.sr_item_sk = i.i_item_sk
JOIN customer_demographics cd ON sr.sr_cdemo_sk = cd.cd_demo_sk
JOIN household_demographics hd ON sr.sr_hdemo_sk = hd.hd_demo_sk
JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
JOIN inv_agg ON inv_agg.inv_item_sk = i.i_item_sk
JOIN warehouse w ON inv_agg.inv_warehouse_sk = w.w_warehouse_sk
WHERE sr.sr_return_amt_inc_tax > 500
  AND sr.sr_fee BETWEEN 20 AND 50
  AND i.i_current_price < 100
  AND w.w_warehouse_sq_ft > 500000
  AND cd.cd_education_status = '4 yr Degree'
ORDER BY return_amt_rank, sr.sr_ticket_number
LIMIT 100
