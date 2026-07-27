WITH inventory_agg AS (
    SELECT
        inv_warehouse_sk,
        inv_date_sk,
        SUM(inv_quantity_on_hand) AS total_qty_on_hand
    FROM inventory
    GROUP BY inv_warehouse_sk, inv_date_sk
)
SELECT
    d.d_year,
    s.s_state,
    cc.cc_name,
    p.p_promo_name,
    hd.hd_buy_potential,
    SUM(cs.cs_net_paid) AS total_net_paid,
    SUM(cr.cr_return_amount) AS total_return_amount,
    SUM(i.total_qty_on_hand) AS total_inventory_qty,
    COUNT(DISTINCT cs.cs_order_number) AS distinct_orders,
    CASE
        WHEN SUM(cs.cs_net_profit) > 100000 THEN 'HIGH'
        ELSE 'LOW'
    END AS profit_category
FROM date_dim d
JOIN catalog_sales cs
    ON cs.cs_sold_date_sk = d.d_date_sk
JOIN call_center cc
    ON cc.cc_open_date_sk = d.d_date_sk
JOIN catalog_page cp
    ON cp.cp_start_date_sk = d.d_date_sk
JOIN catalog_returns cr
    ON cr.cr_returned_date_sk = d.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = d.d_date_sk
JOIN store_returns sr
    ON sr.sr_returned_date_sk = d.d_date_sk
    AND sr.sr_store_sk = s.s_store_sk
JOIN promotion p
    ON p.p_start_date_sk = d.d_date_sk
JOIN warehouse w
    ON cs.cs_warehouse_sk = w.w_warehouse_sk
JOIN inventory_agg i
    ON i.inv_warehouse_sk = w.w_warehouse_sk
    AND i.inv_date_sk = d.d_date_sk
JOIN household_demographics hd
    ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
JOIN income_band ib
    ON hd.hd_income_band_sk = ib.ib_income_band_sk
JOIN customer_demographics cd
    ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
WHERE d.d_year = 2001
  AND s.s_state = 'CA'
  AND cc.cc_mkt_id = 3
  AND cs.cs_quantity > 5
GROUP BY d.d_year, s.s_state, cc.cc_name, p.p_promo_name, hd.hd_buy_potential
ORDER BY total_net_paid DESC
LIMIT 100
