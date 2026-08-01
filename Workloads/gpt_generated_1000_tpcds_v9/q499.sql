WITH inventory_agg AS (
    SELECT
        inv.inv_warehouse_sk,
        inv.inv_item_sk,
        SUM(inv.inv_quantity_on_hand) AS total_on_hand
    FROM inventory inv
    JOIN date_dim d_inv ON inv.inv_date_sk = d_inv.d_date_sk
    WHERE d_inv.d_year = 2001
    GROUP BY inv.inv_warehouse_sk, inv.inv_item_sk
)
SELECT
    w.w_warehouse_name,
    w.w_state,
    i.i_category,
    i.i_brand,
    d.d_year,
    cd.cd_gender,
    ib.ib_lower_bound,
    SUM(cs.cs_net_paid) AS total_sales,
    SUM(cs.cs_net_profit) AS total_profit,
    SUM(cr.cr_return_amount) AS total_catalog_return_amount,
    SUM(sr.sr_return_amt) AS total_store_return_amount,
    SUM(wr.wr_return_amt) AS total_web_return_amount,
    COUNT(DISTINCT cs.cs_order_number) AS distinct_orders,
    CASE WHEN SUM(cs.cs_net_profit) > 100000 THEN 'High' ELSE 'Low' END AS profit_category
FROM catalog_sales cs
JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN item i ON cs.cs_item_sk = i.i_item_sk
JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
JOIN inventory_agg inv ON inv.inv_warehouse_sk = w.w_warehouse_sk
    AND inv.inv_item_sk = i.i_item_sk
LEFT JOIN catalog_returns cr ON cs.cs_order_number = cr.cr_order_number
    AND cr.cr_item_sk = i.i_item_sk
LEFT JOIN store_returns sr ON sr.sr_item_sk = i.i_item_sk
    AND sr.sr_returned_date_sk = d.d_date_sk
LEFT JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
LEFT JOIN web_returns wr ON wr.wr_item_sk = i.i_item_sk
    AND wr.wr_returned_date_sk = d.d_date_sk
WHERE
    d.d_year = 2001
    AND i.i_category = 'Sports'
    AND hd.hd_buy_potential = '1001-5000'
    AND ib.ib_lower_bound >= 30000
    AND p.p_discount_active = 'Y'
    AND w.w_warehouse_sq_ft > 100000
    AND r.r_reason_desc = 'Damaged'
GROUP BY
    w.w_warehouse_name,
    w.w_state,
    i.i_category,
    i.i_brand,
    d.d_year,
    cd.cd_gender,
    ib.ib_lower_bound
ORDER BY total_sales DESC
