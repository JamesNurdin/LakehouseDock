WITH inv_agg AS (
    SELECT
        inv_item_sk,
        inv_warehouse_sk,
        SUM(inv_quantity_on_hand) AS total_qty_on_hand
    FROM inventory
    WHERE inv_quantity_on_hand > 0
    GROUP BY inv_item_sk, inv_warehouse_sk
)
SELECT
    s.s_store_id,
    s.s_store_name,
    i.i_category,
    ds.d_year,
    SUM(ss.ss_net_profit) AS total_sales_profit,
    SUM(cr.cr_return_amount) AS total_return_amount,
    SUM(ss.ss_net_profit) - COALESCE(SUM(cr.cr_return_amount), 0) AS net_profit_after_returns,
    CASE
        WHEN SUM(ss.ss_net_profit) - COALESCE(SUM(cr.cr_return_amount), 0) > 100000 THEN 'HIGH'
        WHEN SUM(ss.ss_net_profit) - COALESCE(SUM(cr.cr_return_amount), 0) > 50000 THEN 'MEDIUM'
        ELSE 'LOW'
    END AS profit_category,
    RANK() OVER (PARTITION BY ds.d_year ORDER BY SUM(ss.ss_net_profit) - COALESCE(SUM(cr.cr_return_amount), 0) DESC) AS profit_rank,
    (SELECT AVG(cr2.cr_return_amount)
     FROM catalog_returns cr2
     WHERE cr2.cr_warehouse_sk = w.w_warehouse_sk) AS avg_return_amount_per_warehouse
FROM store_sales ss
JOIN date_dim ds ON ss.ss_sold_date_sk = ds.d_date_sk
JOIN item i ON ss.ss_item_sk = i.i_item_sk
JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
JOIN store s ON ss.ss_store_sk = s.s_store_sk
LEFT JOIN inv_agg ia ON ia.inv_item_sk = i.i_item_sk
LEFT JOIN warehouse w ON ia.inv_warehouse_sk = w.w_warehouse_sk
LEFT JOIN catalog_returns cr ON cr.cr_item_sk = i.i_item_sk
    AND cr.cr_returned_date_sk = ds.d_date_sk
    AND cr.cr_warehouse_sk = w.w_warehouse_sk
LEFT JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
LEFT JOIN date_dim dr ON cr.cr_returned_date_sk = dr.d_date_sk
LEFT JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
WHERE
    ds.d_year = 2001
    AND i.i_brand = 'Brand#45'
    AND s.s_state = 'TX'
    AND hd.hd_income_band_sk = 5
    AND ss.ss_quantity > 3
    AND (cr.cr_return_quantity > 0 OR cr.cr_return_quantity IS NULL)
GROUP BY
    s.s_store_id,
    s.s_store_name,
    i.i_category,
    ds.d_year,
    w.w_warehouse_sk
ORDER BY
    total_sales_profit DESC
LIMIT 100
