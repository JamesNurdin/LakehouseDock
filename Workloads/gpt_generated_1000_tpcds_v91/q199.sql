SELECT
    d.d_year,
    d.d_month_seq,
    i.i_item_id,
    i.i_product_name,
    i.i_category,
    p.p_promo_name,
    sm.sm_type,
    cd.cd_gender,
    hd.hd_buy_potential,
    ib.ib_lower_bound,
    cs.cs_net_profit,
    cr.cr_return_amount,
    sr.sr_return_amt_inc_tax,
    ws.ws_net_profit,
    wr.wr_return_amt_inc_tax,
    (
        SELECT SUM(inv2.inv_quantity_on_hand)
        FROM inventory inv2
        WHERE inv2.inv_item_sk = cs.cs_item_sk
    ) AS total_inventory_qty,
    RANK() OVER (PARTITION BY d.d_year ORDER BY cs.cs_net_profit DESC) AS profit_rank
FROM catalog_sales cs
JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
JOIN time_dim t ON cs.cs_sold_time_sk = t.t_time_sk
JOIN item i ON cs.cs_item_sk = i.i_item_sk
JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
LEFT JOIN catalog_returns cr ON cr.cr_order_number = cs.cs_order_number
                            AND cr.cr_item_sk = cs.cs_item_sk
LEFT JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
LEFT JOIN store_sales ss ON ss.ss_item_sk = i.i_item_sk
LEFT JOIN store_returns sr ON sr.sr_item_sk = i.i_item_sk
                            AND sr.sr_ticket_number = ss.ss_ticket_number
LEFT JOIN web_sales ws ON ws.ws_item_sk = i.i_item_sk
LEFT JOIN web_returns wr ON wr.wr_item_sk = i.i_item_sk
                            AND wr.wr_order_number = ws.ws_order_number
LEFT JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk
                         AND inv.inv_date_sk = d.d_date_sk
WHERE
    d.d_year = 2001
    AND i.i_category = 'Electronics'
    AND p.p_discount_active = 'Y'
    AND sm.sm_type = 'AIR'
    AND cd.cd_gender = 'M'
    AND hd.hd_buy_potential = '50000-59999'
    AND ib.ib_lower_bound >= 50000
    AND cs.cs_net_profit > 0
    AND cs.cs_quantity > 0
    AND cr.cr_return_amount > 0
ORDER BY profit_rank
LIMIT 100
