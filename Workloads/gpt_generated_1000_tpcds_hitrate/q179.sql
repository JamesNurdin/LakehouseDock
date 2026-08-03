WITH inv_agg AS (
    SELECT
        inv_item_sk,
        inv_date_sk,
        SUM(inv_quantity_on_hand) AS total_qty
    FROM inventory
    GROUP BY inv_item_sk, inv_date_sk
)
SELECT
    d.d_year,
    s.s_store_name,
    i.i_brand,
    r.r_reason_desc,
    COUNT(DISTINCT sr.sr_ticket_number) AS return_transactions,
    SUM(sr.sr_return_amt) AS total_return_amount,
    AVG(sr.sr_return_amt_inc_tax) AS avg_return_inc_tax,
    MAX(inv_agg.total_qty) AS max_inventory_qty,
    MIN(i.i_current_price) AS min_item_price
FROM store_returns sr
JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
JOIN time_dim t ON sr.sr_return_time_sk = t.t_time_sk
JOIN item i ON sr.sr_item_sk = i.i_item_sk
JOIN household_demographics hd ON sr.sr_hdemo_sk = hd.hd_demo_sk
JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
JOIN store s ON sr.sr_store_sk = s.s_store_sk
JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
JOIN inv_agg ON inv_agg.inv_item_sk = i.i_item_sk AND inv_agg.inv_date_sk = d.d_date_sk
JOIN catalog_page cp ON cp.cp_start_date_sk = d.d_date_sk
JOIN web_page wp ON wp.wp_creation_date_sk = d.d_date_sk
JOIN web_site ws ON ws.web_open_date_sk = d.d_date_sk
WHERE d.d_year = 2001
  AND s.s_state = 'TX'
  AND ib.ib_upper_bound >= 50000
  AND i.i_current_price BETWEEN 10 AND 100
  AND hd.hd_vehicle_count >= 1
  AND EXISTS (
        SELECT 1
        FROM web_page wp2
        WHERE wp2.wp_url LIKE '%example%'
          AND wp2.wp_creation_date_sk = d.d_date_sk
    )
GROUP BY d.d_year, s.s_store_name, i.i_brand, r.r_reason_desc
ORDER BY total_return_amount DESC
LIMIT 100
