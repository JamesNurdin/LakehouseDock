WITH inv_agg AS (
    SELECT
        i.i_item_sk,
        w.w_warehouse_sk,
        SUM(inv.inv_quantity_on_hand) AS total_qty_on_hand
    FROM inventory inv
    JOIN item i ON inv.inv_item_sk = i.i_item_sk
    JOIN warehouse w ON inv.inv_warehouse_sk = w.w_warehouse_sk
    GROUP BY i.i_item_sk, w.w_warehouse_sk
),
web_ret_total AS (
    SELECT
        i.i_item_sk,
        d.d_year,
        SUM(wr.wr_return_amt) AS web_return_amt
    FROM web_returns wr
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN item i ON wr.wr_item_sk = i.i_item_sk
    GROUP BY i.i_item_sk, d.d_year
)
SELECT
    s.s_store_name,
    i.i_product_name,
    p.p_promo_name,
    d_sold.d_year,
    SUM(ss.ss_ext_sales_price) AS total_sales,
    SUM(COALESCE(sr.sr_return_amt, 0)) AS total_store_returns,
    COALESCE(wr_tot.web_return_amt, 0) AS total_web_returns,
    SUM(COALESCE(ia.total_qty_on_hand, 0)) AS total_inventory_qty,
    COUNT(DISTINCT p.p_promo_id) AS distinct_promo_ids,
    cc.cc_name,
    cp.cp_department,
    wsit.web_name,
    wp.wp_url,
    r.r_reason_desc
FROM store_sales ss
JOIN date_dim d_sold ON ss.ss_sold_date_sk = d_sold.d_date_sk
JOIN time_dim t_sold ON ss.ss_sold_time_sk = t_sold.t_time_sk
JOIN store s ON ss.ss_store_sk = s.s_store_sk
JOIN item i ON ss.ss_item_sk = i.i_item_sk
JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
LEFT JOIN store_returns sr ON sr.sr_ticket_number = ss.ss_ticket_number
    AND sr.sr_item_sk = ss.ss_item_sk
LEFT JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
JOIN inv_agg ia ON ia.i_item_sk = i.i_item_sk
JOIN warehouse w ON w.w_warehouse_sk = ia.w_warehouse_sk
JOIN call_center cc ON cc.cc_open_date_sk = d_sold.d_date_sk
JOIN catalog_page cp ON cp.cp_start_date_sk = d_sold.d_date_sk
JOIN web_site wsit ON wsit.web_open_date_sk = d_sold.d_date_sk
JOIN web_page wp ON wp.wp_creation_date_sk = d_sold.d_date_sk
LEFT JOIN web_ret_total wr_tot ON wr_tot.i_item_sk = i.i_item_sk
    AND wr_tot.d_year = d_sold.d_year
WHERE EXISTS (
    SELECT 1
    FROM web_sales ws
    JOIN date_dim d_ws ON ws.ws_sold_date_sk = d_ws.d_date_sk
    WHERE ws.ws_bill_customer_sk = c.c_customer_sk
      AND d_ws.d_year = d_sold.d_year
      AND ws.ws_item_sk = i.i_item_sk
)
GROUP BY
    s.s_store_name,
    i.i_product_name,
    p.p_promo_name,
    d_sold.d_year,
    wr_tot.web_return_amt,
    ia.total_qty_on_hand,
    cc.cc_name,
    cp.cp_department,
    wsit.web_name,
    wp.wp_url,
    r.r_reason_desc
ORDER BY total_sales DESC
LIMIT 100
