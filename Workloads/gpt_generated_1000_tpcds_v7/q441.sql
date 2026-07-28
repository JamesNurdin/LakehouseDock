WITH joined_data AS (
    SELECT
        w.w_warehouse_name,
        i.i_brand,
        d.d_year,
        sr.sr_net_loss,
        sr.sr_return_amt,
        inv.inv_quantity_on_hand,
        ib.ib_upper_bound,
        ca.ca_state
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN time_dim t ON sr.sr_return_time_sk = t.t_time_sk
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
    JOIN household_demographics hd ON sr.sr_hdemo_sk = hd.hd_demo_sk
    JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    LEFT JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk AND inv.inv_date_sk = d.d_date_sk
    LEFT JOIN warehouse w ON inv.inv_warehouse_sk = w.w_warehouse_sk
    LEFT JOIN catalog_returns cr ON cr.cr_returned_date_sk = d.d_date_sk AND cr.cr_item_sk = i.i_item_sk
    LEFT JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    LEFT JOIN web_returns wr ON wr.wr_returned_date_sk = d.d_date_sk AND wr.wr_item_sk = i.i_item_sk
    LEFT JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
    LEFT JOIN web_site ws ON ws.web_open_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
      AND i.i_current_price > 5.00
      AND ca.ca_state = 'CA'
      AND ib.ib_upper_bound >= 50000
      AND w.w_city = 'Seattle'
)
SELECT
    w_warehouse_name,
    i_brand,
    d_year,
    SUM(sr_net_loss) AS total_net_loss,
    SUM(sr_return_amt) AS total_return_amount,
    AVG(inv_quantity_on_hand) AS avg_quantity_on_hand,
    COUNT(*) AS txn_count
FROM joined_data
GROUP BY w_warehouse_name, i_brand, d_year
HAVING SUM(sr_net_loss) > 1000
ORDER BY total_net_loss DESC
LIMIT 100
