WITH
    filtered_inventory AS (
        SELECT inv.inv_item_sk, inv.inv_quantity_on_hand, inv.inv_date_sk
        FROM inventory inv TABLESAMPLE BERNOULLI (10)
        WHERE inv.inv_quantity_on_hand > 500
    ),
    high_return_items AS (
        SELECT DISTINCT sr.sr_item_sk
        FROM store_returns sr
        WHERE sr.sr_return_amt > 100
    ),
    common_items AS (
        SELECT fi.inv_item_sk
        FROM filtered_inventory fi
        INTERSECT
        SELECT hi.sr_item_sk
        FROM high_return_items hi
    ),
    excluded_items AS (
        SELECT DISTINCT sr.sr_item_sk
        FROM store_returns sr
        WHERE sr.sr_return_quantity = 0
    ),
    unique_items AS (
        SELECT ci.inv_item_sk
        FROM common_items ci
        EXCEPT
        SELECT ei.sr_item_sk
        FROM excluded_items ei
    )
SELECT
    s.s_store_id,
    d.d_year,
    hd.hd_buy_potential,
    COUNT(*) AS return_cnt,
    SUM(sr.sr_return_amt) AS total_return_amt,
    AVG(sr.sr_return_amt) AS avg_return_amt,
    COUNT(DISTINCT i.i_brand) AS distinct_brand_cnt,
    COUNT(DISTINCT inv.inv_quantity_on_hand) AS distinct_quantity_cnt,
    CASE WHEN ib.ib_upper_bound > 50000 THEN 'High' ELSE 'Low' END AS income_band_category,
    (SELECT SUM(sr2.sr_return_amt)
     FROM store_returns sr2
     WHERE sr2.sr_store_sk = s.s_store_sk) AS store_total_return_amt,
    SUM(inv.inv_quantity_on_hand) AS total_inventory_qty
FROM store_returns sr
JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
JOIN item i ON sr.sr_item_sk = i.i_item_sk
JOIN store s ON sr.sr_store_sk = s.s_store_sk
JOIN household_demographics hd ON sr.sr_hdemo_sk = hd.hd_demo_sk
JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
JOIN catalog_page cp ON cp.cp_start_date_sk = d.d_date_sk
JOIN (SELECT * FROM inventory TABLESAMPLE BERNOULLI (10)) inv
     ON inv.inv_item_sk = i.i_item_sk
    AND inv.inv_date_sk = d.d_date_sk
JOIN unique_items ui ON i.i_item_sk = ui.inv_item_sk
WHERE
    d.d_year = 2001
    AND s.s_market_id IN (10, 3, 7)
    AND i.i_category_id = 1
    AND hd.hd_buy_potential = '501-1000'
    AND ib.ib_upper_bound <= 20000
    AND cp.cp_type = 'PROMO'
    AND hd.hd_vehicle_count >= 2
    AND inv.inv_quantity_on_hand > 500
GROUP BY
    s.s_store_id,
    d.d_year,
    hd.hd_buy_potential,
    ib.ib_upper_bound,
    cp.cp_type,
    s.s_store_sk
HAVING
    SUM(sr.sr_return_amt) > 500
ORDER BY
    total_return_amt DESC
LIMIT 100
