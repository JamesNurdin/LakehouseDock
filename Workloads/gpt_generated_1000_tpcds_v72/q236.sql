WITH filtered_date AS (
    SELECT d_date_sk, d_year, d_date
    FROM date_dim
    WHERE d_date >= DATE '2000-01-01'
      AND d_date < DATE '2001-01-01'
)
SELECT
    d.d_year,
    p.p_promo_id,
    w.w_warehouse_name,
    SUM(ss.ss_net_profit)               AS store_net_profit,
    SUM(cs.cs_net_profit)               AS catalog_net_profit,
    SUM(cr.cr_net_loss)                 AS catalog_returns_loss,
    SUM(wr.wr_net_loss)                 AS web_returns_loss,
    COUNT(DISTINCT ss.ss_ticket_number) AS store_transactions,
    COUNT(DISTINCT cs.cs_order_number)  AS catalog_transactions,
    AVG(p.p_cost)                       AS avg_promo_cost,
    MAX(ib.ib_upper_bound)              AS max_income_upper
FROM filtered_date d
JOIN store_sales ss      ON ss.ss_sold_date_sk = d.d_date_sk
JOIN time_dim t          ON ss.ss_sold_time_sk = t.t_time_sk
JOIN promotion p         ON ss.ss_promo_sk = p.p_promo_sk
JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
JOIN income_band ib      ON hd.hd_income_band_sk = ib.ib_income_band_sk
JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
JOIN catalog_sales cs   ON cs.cs_sold_date_sk = d.d_date_sk
JOIN catalog_page cp    ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN warehouse w        ON cs.cs_warehouse_sk = w.w_warehouse_sk
JOIN catalog_returns cr ON cr.cr_returned_date_sk = d.d_date_sk
                         AND cr.cr_order_number = cs.cs_order_number
JOIN web_returns wr    ON wr.wr_returned_date_sk = d.d_date_sk
JOIN call_center cc     ON cc.cc_open_date_sk = d.d_date_sk
JOIN web_site ws        ON ws.web_open_date_sk = d.d_date_sk
WHERE ss.ss_quantity > 1
  AND p.p_discount_active = 'Y'
  AND w.w_state = 'CA'
  AND EXISTS (
        SELECT 1
        FROM inventory inv_sub
        WHERE inv_sub.inv_warehouse_sk = w.w_warehouse_sk
          AND inv_sub.inv_quantity_on_hand > 1000
    )
GROUP BY d.d_year, p.p_promo_id, w.w_warehouse_name
ORDER BY d.d_year DESC, store_net_profit DESC
LIMIT 100
