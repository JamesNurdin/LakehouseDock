WITH item_avg_price AS (
    SELECT i_category, AVG(i_current_price) AS avg_price
    FROM item
    GROUP BY i_category
)
SELECT
    d_sold.d_year,
    i.i_brand,
    CASE WHEN ss.ss_net_profit > 1000 THEN 'High' ELSE 'Low' END AS profit_category,
    SUM(ss.ss_net_paid) AS total_store_net_paid,
    COUNT(DISTINCT ss.ss_ticket_number) AS store_transactions,
    AVG(ws.ws_net_profit) AS avg_web_profit,
    MIN(inv.inv_quantity_on_hand) AS min_inventory_qty,
    MAX(p.p_cost) AS max_promo_cost,
    ib.ib_upper_bound,
    (
        SELECT avg_price
        FROM item_avg_price ap
        WHERE ap.i_category = i.i_category
    ) AS category_avg_price
FROM store_sales ss
JOIN date_dim d_sold
  ON ss.ss_sold_date_sk = d_sold.d_date_sk
JOIN item i
  ON ss.ss_item_sk = i.i_item_sk
JOIN promotion p
  ON ss.ss_promo_sk = p.p_promo_sk
JOIN household_demographics hd_store
  ON ss.ss_hdemo_sk = hd_store.hd_demo_sk
JOIN income_band ib
  ON hd_store.hd_income_band_sk = ib.ib_income_band_sk
JOIN inventory inv
  ON inv.inv_item_sk = i.i_item_sk
JOIN date_dim d_inv
  ON inv.inv_date_sk = d_inv.d_date_sk
JOIN date_dim d_promo_start
  ON p.p_start_date_sk = d_promo_start.d_date_sk
JOIN date_dim d_promo_end
  ON p.p_end_date_sk = d_promo_end.d_date_sk
JOIN web_sales ws
  ON ws.ws_item_sk = i.i_item_sk
JOIN date_dim d_ws_sold
  ON ws.ws_sold_date_sk = d_ws_sold.d_date_sk
JOIN date_dim d_ws_ship
  ON ws.ws_ship_date_sk = d_ws_ship.d_date_sk
JOIN household_demographics hd_bill
  ON ws.ws_bill_hdemo_sk = hd_bill.hd_demo_sk
WHERE d_sold.d_year = 2001
  AND d_sold.d_month_seq BETWEEN 1200 AND 1210
  AND i.i_brand = 'Brand#12'
  AND i.i_current_price > 50
  AND hd_store.hd_vehicle_count >= 2
  AND ib.ib_upper_bound <= 100000
  AND inv.inv_quantity_on_hand > 500
  AND p.p_discount_active = 'Y'
  AND d_promo_start.d_year = 2001
  AND d_promo_end.d_year >= 2001
GROUP BY
    d_sold.d_year,
    i.i_brand,
    CASE WHEN ss.ss_net_profit > 1000 THEN 'High' ELSE 'Low' END,
    ib.ib_upper_bound,
    i.i_category
ORDER BY total_store_net_paid DESC
LIMIT 100
