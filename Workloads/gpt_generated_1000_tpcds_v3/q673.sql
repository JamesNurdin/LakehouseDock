SELECT
    s.s_store_name,
    d.d_date,
    i.i_product_name,
    sr.sr_return_quantity,
    sr.sr_return_amt,
    sr.sr_net_loss,
    CASE
        WHEN sr.sr_net_loss > 100 THEN 'High'
        WHEN sr.sr_net_loss > 0 THEN 'Medium'
        ELSE 'Low'
    END AS loss_category,
    ROW_NUMBER() OVER (PARTITION BY s.s_store_name ORDER BY sr.sr_net_loss DESC) AS loss_rank,
    cc.cc_name,
    cp.cp_description,
    ws.web_name,
    ib.ib_lower_bound,
    hd.hd_buy_potential,
    p.p_promo_name
FROM store_returns sr
JOIN date_dim d
    ON sr.sr_returned_date_sk = d.d_date_sk
JOIN item i
    ON sr.sr_item_sk = i.i_item_sk
JOIN inventory inv
    ON i.i_item_sk = inv.inv_item_sk
JOIN warehouse w
    ON inv.inv_warehouse_sk = w.w_warehouse_sk
JOIN store s
    ON sr.sr_store_sk = s.s_store_sk
JOIN reason r
    ON sr.sr_reason_sk = r.r_reason_sk
JOIN customer_demographics cd
    ON sr.sr_cdemo_sk = cd.cd_demo_sk
JOIN household_demographics hd
    ON sr.sr_hdemo_sk = hd.hd_demo_sk
JOIN income_band ib
    ON hd.hd_income_band_sk = ib.ib_income_band_sk
JOIN promotion p
    ON p.p_item_sk = i.i_item_sk
JOIN call_center cc
    ON cc.cc_closed_date_sk = d.d_date_sk
JOIN catalog_page cp
    ON cp.cp_start_date_sk = d.d_date_sk
JOIN web_site ws
    ON ws.web_open_date_sk = d.d_date_sk
WHERE d.d_qoy = 4
  AND i.i_class_id IN (3, 4, 10)
  AND w.w_zip = '89275'
  AND ib.ib_upper_bound > 50000
  AND p.p_cost > 1000
  AND cd.cd_dep_count >= 2
ORDER BY sr.sr_net_loss DESC
LIMIT 100
