WITH sales_agg AS (
    SELECT
        i.i_item_sk,
        i.i_item_id,
        s.s_store_sk,
        s.s_store_name,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        SUM(ss.ss_net_profit) AS total_profit
    FROM store_sales ss
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    WHERE i.i_current_price > 100
      AND s.s_state = 'CA'
      AND i.i_rec_start_date >= DATE '2022-01-01'
    GROUP BY i.i_item_sk, i.i_item_id, s.s_store_sk, s.s_store_name
)
SELECT
    sa.i_item_id,
    sa.s_store_name,
    sa.total_sales,
    sa.total_profit,
    CASE WHEN sa.total_profit > 0 THEN 'Profitable' ELSE 'Loss' END AS profit_flag,
    cr.cr_return_amount,
    sr.sr_return_amt,
    inv.inv_quantity_on_hand,
    ib.ib_upper_bound AS income_upper,
    wp.wp_link_count,
    RANK() OVER (PARTITION BY sa.s_store_sk ORDER BY sa.total_sales DESC) AS store_sales_rank,
    DENSE_RANK() OVER (ORDER BY sa.total_sales DESC) AS overall_sales_rank,
    (SELECT AVG(inv_quantity_on_hand) FROM inventory WHERE inv_item_sk = sa.i_item_sk) AS avg_inventory_qty
FROM sales_agg sa
JOIN store_sales ss
    ON ss.ss_item_sk = sa.i_item_sk
   AND ss.ss_store_sk = sa.s_store_sk
JOIN household_demographics hd
    ON ss.ss_hdemo_sk = hd.hd_demo_sk
JOIN customer_demographics cd
    ON ss.ss_cdemo_sk = cd.cd_demo_sk
JOIN customer_address ca
    ON ss.ss_addr_sk = ca.ca_address_sk
JOIN customer c
    ON ss.ss_customer_sk = c.c_customer_sk
JOIN web_page wp
    ON wp.wp_customer_sk = c.c_customer_sk
JOIN income_band ib
    ON hd.hd_income_band_sk = ib.ib_income_band_sk
LEFT JOIN inventory inv
    ON inv.inv_item_sk = sa.i_item_sk
LEFT JOIN catalog_returns cr
    ON cr.cr_item_sk = sa.i_item_sk
   AND cr.cr_refunded_customer_sk = c.c_customer_sk
LEFT JOIN store_returns sr
    ON sr.sr_item_sk = sa.i_item_sk
   AND sr.sr_ticket_number = ss.ss_ticket_number
LEFT JOIN catalog_page cp
    ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
LEFT JOIN ship_mode sm
    ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
LEFT JOIN reason r
    ON cr.cr_reason_sk = r.r_reason_sk
WHERE wp.wp_link_count > 5
  AND cp.cp_department = 'Electronics'
  AND sm.sm_code = 'AIR'
ORDER BY overall_sales_rank
LIMIT 100
