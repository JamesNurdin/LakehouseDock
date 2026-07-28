/*
  Goal: Calculate the average total return amount (catalog, store, and web) and the average inventory on hand per income band for the year 2001, applying multiple filters on price, vehicle count, income bounds, return quantity and state. The query joins all 13 selected TPC‑DS tables, uses a DISTINCT sub‑query, aggregates twice (CTE then outer query), and orders the final result by average return descending.
*/
WITH distinct_items AS (
    SELECT DISTINCT i_item_sk, i_item_id, i_product_name, i_current_price
    FROM item
),
joined_data AS (
    SELECT
        d.d_date,
        d.d_year,
        t.t_hour,
        di.i_item_sk,
        di.i_item_id,
        di.i_product_name,
        di.i_current_price,
        cr.cr_return_amount,
        cr.cr_return_quantity,
        cr.cr_fee,
        sr.sr_return_amt,
        sr.sr_return_quantity,
        wr.wr_return_amt,
        wr.wr_return_quantity,
        inv.inv_quantity_on_hand,
        ib.ib_income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        hd.hd_buy_potential,
        hd.hd_vehicle_count,
        ca.ca_state,
        sm.sm_ship_mode_id,
        ws.web_name
    FROM catalog_returns cr
    JOIN date_dim d
        ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN time_dim t
        ON cr.cr_returned_time_sk = t.t_time_sk
    JOIN distinct_items di
        ON cr.cr_item_sk = di.i_item_sk
    JOIN customer_demographics cd
        ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd
        ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN customer_address ca
        ON cr.cr_refunded_addr_sk = ca.ca_address_sk
    JOIN ship_mode sm
        ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN store_returns sr
        ON sr.sr_returned_date_sk = d.d_date_sk
        AND sr.sr_item_sk = di.i_item_sk
    JOIN web_returns wr
        ON wr.wr_returned_date_sk = d.d_date_sk
        AND wr.wr_item_sk = di.i_item_sk
    JOIN inventory inv
        ON inv.inv_date_sk = d.d_date_sk
        AND inv.inv_item_sk = di.i_item_sk
    JOIN web_site ws
        ON ws.web_open_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
      AND di.i_current_price > 20
      AND hd.hd_vehicle_count >= 2
      AND ib.ib_lower_bound >= 20000
      AND cr.cr_return_quantity > 0
      AND ca.ca_state = 'TX'
),
aggregated AS (
    SELECT
        d_date,
        i_item_id,
        ib_income_band_sk,
        ib_lower_bound,
        ib_upper_bound,
        SUM(cr_return_amount) AS total_catalog_return,
        SUM(sr_return_amt) AS total_store_return,
        SUM(wr_return_amt) AS total_web_return,
        AVG(inv_quantity_on_hand) AS avg_inventory_on_hand
    FROM joined_data
    GROUP BY d_date, i_item_id, ib_income_band_sk, ib_lower_bound, ib_upper_bound
)
SELECT
    ib_income_band_sk,
    ib_lower_bound,
    ib_upper_bound,
    AVG(total_catalog_return + total_store_return + total_web_return) AS avg_total_return,
    AVG(avg_inventory_on_hand) AS avg_inventory
FROM aggregated
WHERE ib_upper_bound <= 160000
  AND ib_lower_bound >= 20000
GROUP BY ib_income_band_sk, ib_lower_bound, ib_upper_bound
HAVING AVG(total_catalog_return + total_store_return + total_web_return) > 1000
ORDER BY avg_total_return DESC
LIMIT 50
