WITH inv_agg AS (
    SELECT
        inv_item_sk,
        inv_date_sk,
        SUM(inv_quantity_on_hand) AS total_qty
    FROM inventory
    WHERE inv_quantity_on_hand > 0
    GROUP BY inv_item_sk, inv_date_sk
)
SELECT
    d.d_year,
    i.i_category,
    w.web_name,
    COUNT(DISTINCT ss.ss_store_sk) AS distinct_store_cnt,
    SUM(ss.ss_net_profit) AS total_net_profit,
    AVG(ss.ss_net_paid) AS avg_net_paid,
    SUM(sr.sr_net_loss) AS total_return_loss,
    SUM(inv_agg.total_qty) AS total_inventory_qty,
    (SELECT MAX(ib2.ib_upper_bound) FROM income_band ib2) AS max_income_upper_bound
FROM date_dim d
JOIN store_sales ss
    ON ss.ss_sold_date_sk = d.d_date_sk
JOIN store_returns sr
    ON sr.sr_returned_date_sk = d.d_date_sk
   AND sr.sr_item_sk = ss.ss_item_sk
JOIN item i
    ON ss.ss_item_sk = i.i_item_sk
   AND sr.sr_item_sk = i.i_item_sk
JOIN household_demographics hd
    ON ss.ss_hdemo_sk = hd.hd_demo_sk
   AND sr.sr_hdemo_sk = hd.hd_demo_sk
JOIN income_band ib
    ON hd.hd_income_band_sk = ib.ib_income_band_sk
JOIN catalog_sales cs
    ON cs.cs_item_sk = i.i_item_sk
   AND cs.cs_sold_date_sk = d.d_date_sk
JOIN catalog_returns cr
    ON cr.cr_returned_date_sk = d.d_date_sk
   AND cr.cr_item_sk = i.i_item_sk
   AND cr.cr_order_number = cs.cs_order_number
JOIN call_center cc
    ON cs.cs_call_center_sk = cc.cc_call_center_sk
   AND cr.cr_call_center_sk = cc.cc_call_center_sk
JOIN reason r
    ON sr.sr_reason_sk = r.r_reason_sk
   AND cr.cr_reason_sk = r.r_reason_sk
JOIN inv_agg
    ON inv_agg.inv_item_sk = i.i_item_sk
   AND inv_agg.inv_date_sk = d.d_date_sk
JOIN web_site w
    ON w.web_open_date_sk = d.d_date_sk
WHERE d.d_year = 2001
  AND i.i_current_price BETWEEN 50 AND 200
  AND hd.hd_buy_potential = '1001-5000'
  AND cc.cc_state = 'CA'
  AND w.web_country = 'United States'
  AND ib.ib_lower_bound >= 30000
  AND EXISTS (
        SELECT 1
        FROM catalog_returns cr_sub
        WHERE cr_sub.cr_item_sk = i.i_item_sk
      )
GROUP BY d.d_year, i.i_category, w.web_name
ORDER BY total_net_profit DESC
LIMIT 100
