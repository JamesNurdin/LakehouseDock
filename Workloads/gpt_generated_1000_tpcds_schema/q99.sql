WITH inv_agg AS (
    SELECT inv_warehouse_sk,
           SUM(inv_quantity_on_hand) AS total_qty
    FROM inventory
    GROUP BY inv_warehouse_sk
),
store_full AS (
    SELECT s.s_store_sk,
           s.s_store_name,
           sr.sr_return_amt,
           sr.sr_customer_sk,
           sr.sr_hdemo_sk
    FROM store s
    FULL OUTER JOIN store_returns sr
        ON s.s_store_sk = sr.sr_store_sk
)
SELECT
    cs.cs_order_number,
    cs.cs_net_paid,
    cp.cp_department,
    sm.sm_ship_mode_id,
    w.w_warehouse_name,
    inv_agg.total_qty,
    hd_bill.hd_buy_potential,
    ib.ib_lower_bound,
    c_bill.c_first_name,
    c_bill.c_last_name,
    sf.s_store_name,
    wp.wp_url,
    sf.sr_return_amt,
    wr.wr_return_amt
FROM catalog_sales cs
-- retain every ship mode, even if no sales exist
RIGHT JOIN ship_mode sm
    ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
LEFT JOIN catalog_page cp
    ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
LEFT JOIN warehouse w
    ON cs.cs_warehouse_sk = w.w_warehouse_sk
LEFT JOIN inv_agg
    ON w.w_warehouse_sk = inv_agg.inv_warehouse_sk
-- join the billing customer (first alias)
LEFT JOIN customer c_bill
    ON cs.cs_bill_customer_sk = c_bill.c_customer_sk
-- join the shipping customer (second alias of the same table)
LEFT JOIN customer c_ship
    ON cs.cs_ship_customer_sk = c_ship.c_customer_sk
LEFT JOIN household_demographics hd_bill
    ON cs.cs_bill_hdemo_sk = hd_bill.hd_demo_sk
LEFT JOIN income_band ib
    ON hd_bill.hd_income_band_sk = ib.ib_income_band_sk
-- bring in store information and any associated store returns via a full outer join
LEFT JOIN store_full sf
    ON sf.sr_customer_sk = c_bill.c_customer_sk
LEFT JOIN web_returns wr
    ON wr.wr_refunded_customer_sk = c_bill.c_customer_sk
LEFT JOIN web_page wp
    ON wr.wr_web_page_sk = wp.wp_web_page_sk
WHERE cs.cs_order_number NOT IN (
    SELECT sr_ticket_number FROM store_returns
)
ORDER BY cs.cs_net_paid DESC
LIMIT 100
