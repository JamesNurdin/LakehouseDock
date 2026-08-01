WITH filtered_returns AS (
   SELECT
       sr.sr_returned_date_sk,
       sr.sr_return_time_sk,
       sr.sr_item_sk,
       sr.sr_return_quantity,
       sr.sr_return_amt,
       i.i_current_price,
       d.d_year,
       t.t_meal_time,
       cd.cd_gender,
       hd.hd_income_band_sk,
       ib.ib_lower_bound,
       inv.inv_quantity_on_hand,
       w.w_warehouse_name,
       cc.cc_name,
       cp.cp_catalog_number,
       wp.wp_url,
       ws.web_name,
       CASE
           WHEN sr.sr_return_amt > 50 THEN 'High'
           ELSE 'Low'
       END AS return_category
   FROM store_returns sr
   JOIN item i ON sr.sr_item_sk = i.i_item_sk
   JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
   JOIN time_dim t ON sr.sr_return_time_sk = t.t_time_sk
   JOIN customer_demographics cd ON sr.sr_cdemo_sk = cd.cd_demo_sk
   JOIN household_demographics hd ON sr.sr_hdemo_sk = hd.hd_demo_sk
   JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
   JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk AND inv.inv_date_sk = d.d_date_sk
   JOIN warehouse w ON inv.inv_warehouse_sk = w.w_warehouse_sk
   JOIN call_center cc ON cc.cc_open_date_sk = d.d_date_sk
   JOIN (SELECT * FROM catalog_page TABLESAMPLE BERNOULLI (10) ) cp ON cp.cp_start_date_sk = d.d_date_sk
   FULL OUTER JOIN web_page wp ON wp.wp_creation_date_sk = d.d_date_sk
   FULL OUTER JOIN web_site ws ON ws.web_open_date_sk = d.d_date_sk
   WHERE d.d_year BETWEEN 2000 AND 2002
     AND t.t_meal_time IN ('lunch','dinner')
     AND i.i_current_price > 20
     AND ib.ib_upper_bound <= 50000
     AND cc.cc_gmt_offset BETWEEN -5 AND 5
     AND NOT EXISTS (
         SELECT 1 FROM inventory inv2
         WHERE inv2.inv_item_sk = sr.sr_item_sk
           AND inv2.inv_date_sk = sr.sr_returned_date_sk
           AND inv2.inv_quantity_on_hand < 0
     )
),
high_returns AS (
   SELECT
       sr_returned_date_sk,
       sr_return_amt,
       return_category,
       d_year
   FROM filtered_returns
   WHERE sr_return_amt > 100
),
inventory_summary AS (
   SELECT
       inv_date_sk,
       inv_item_sk,
       SUM(inv_quantity_on_hand) AS total_qty,
       CASE WHEN SUM(inv_quantity_on_hand) > 1000 THEN 'Large' ELSE 'Small' END AS qty_category
   FROM inventory
   GROUP BY inv_date_sk, inv_item_sk
   HAVING SUM(inv_quantity_on_hand) > 0
)
SELECT *
FROM (
    SELECT
        fr.sr_returned_date_sk,
        fr.sr_return_amt,
        fr.return_category,
        fr.d_year,
        NULL AS total_qty,
        NULL AS qty_category,
        'return' AS source
    FROM high_returns fr
    UNION ALL
    SELECT
        isum.inv_date_sk,
        NULL AS sr_return_amt,
        NULL AS return_category,
        NULL AS d_year,
        isum.total_qty,
        isum.qty_category,
        'inventory' AS source
    FROM inventory_summary isum
) combined
ORDER BY CASE WHEN source = 'return' THEN sr_return_amt ELSE total_qty END DESC
OFFSET 10
LIMIT 100
