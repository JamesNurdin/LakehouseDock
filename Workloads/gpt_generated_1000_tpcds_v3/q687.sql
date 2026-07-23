WITH inventory_agg AS (
    SELECT
        inv_warehouse_sk,
        inv_date_sk,
        SUM(inv_quantity_on_hand) AS total_quantity_on_hand
    FROM inventory
    GROUP BY inv_warehouse_sk, inv_date_sk
)
SELECT
    s.s_store_name,
    d.d_year,
    p.p_promo_id,
    cp.cp_department,
    hd.hd_buy_potential,
    ib.ib_lower_bound,
    SUM(ss.ss_net_profit) AS total_store_net_profit,
    SUM(cs.cs_net_profit) AS total_catalog_net_profit,
    SUM(cr.cr_net_loss) AS total_catalog_return_loss,
    SUM(sr.sr_net_loss) AS total_store_return_loss,
    SUM(wr.wr_net_loss) AS total_web_return_loss,
    SUM(ia.total_quantity_on_hand) AS total_inventory_qty,
    (SUM(ss.ss_net_profit) / (
        SELECT AVG(ss2.ss_net_profit)
        FROM store_sales ss2
        JOIN date_dim d2 ON ss2.ss_sold_date_sk = d2.d_date_sk
        WHERE d2.d_year = d.d_year
    )) AS profit_vs_year_avg
FROM date_dim d
JOIN store_sales ss ON ss.ss_sold_date_sk = d.d_date_sk
JOIN store s ON ss.ss_store_sk = s.s_store_sk
JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
JOIN catalog_sales cs ON cs.cs_sold_date_sk = d.d_date_sk
JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
JOIN store_returns sr ON sr.sr_returned_date_sk = d.d_date_sk
    AND sr.sr_store_sk = s.s_store_sk
    AND sr.sr_ticket_number = ss.ss_ticket_number
JOIN catalog_returns cr ON cr.cr_returned_date_sk = d.d_date_sk
    AND cr.cr_order_number = cs.cs_order_number
JOIN web_returns wr ON wr.wr_returned_date_sk = d.d_date_sk
JOIN customer_demographics cd ON cd.cd_demo_sk = ss.ss_cdemo_sk
JOIN household_demographics hd ON hd.hd_demo_sk = ss.ss_hdemo_sk
JOIN income_band ib ON ib.ib_income_band_sk = hd.hd_income_band_sk
JOIN inventory_agg ia ON ia.inv_date_sk = d.d_date_sk
    AND ia.inv_warehouse_sk = w.w_warehouse_sk
JOIN web_site ws ON ws.web_open_date_sk = d.d_date_sk
WHERE d.d_year = 2001
  AND s.s_state = 'CA'
  AND w.w_warehouse_sq_ft > 500000
  AND p.p_discount_active = 'N'
  AND hd.hd_buy_potential = '>10000'
GROUP BY
    s.s_store_name,
    d.d_year,
    p.p_promo_id,
    cp.cp_department,
    hd.hd_buy_potential,
    ib.ib_lower_bound
HAVING SUM(ss.ss_net_profit) > 100000
ORDER BY total_store_net_profit DESC
LIMIT 100
