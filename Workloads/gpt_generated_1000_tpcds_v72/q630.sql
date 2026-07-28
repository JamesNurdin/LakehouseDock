WITH inv_agg AS (
    SELECT
        inv.inv_warehouse_sk,
        d.d_year,
        SUM(inv.inv_quantity_on_hand) AS total_qty_on_hand
    FROM inventory inv
    JOIN date_dim d
        ON inv.inv_date_sk = d.d_date_sk
    GROUP BY inv.inv_warehouse_sk, d.d_year
)
SELECT
    c.c_customer_id,
    d.d_year,
    w.w_warehouse_name,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    hd.hd_buy_potential,
    SUM(cs.cs_ext_sales_price) AS total_sales,
    inv_agg.total_qty_on_hand,
    RANK() OVER (PARTITION BY d.d_year ORDER BY SUM(cs.cs_ext_sales_price) DESC) AS sales_rank_by_year,
    CASE
        WHEN hd.hd_vehicle_count > 2 THEN 'High Vehicle'
        ELSE 'Low Vehicle'
    END AS vehicle_category,
    ws.ws_list_price,
    p.p_promo_name,
    r.r_reason_desc,
    ws_site.web_name
FROM catalog_sales cs
JOIN date_dim d
    ON cs.cs_sold_date_sk = d.d_date_sk
JOIN catalog_page cp
    ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN customer c
    ON cs.cs_bill_customer_sk = c.c_customer_sk
JOIN customer_address ca
    ON cs.cs_bill_addr_sk = ca.ca_address_sk
JOIN customer_demographics cd
    ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
JOIN household_demographics hd
    ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
JOIN income_band ib
    ON hd.hd_income_band_sk = ib.ib_income_band_sk
JOIN promotion p
    ON cs.cs_promo_sk = p.p_promo_sk
JOIN warehouse w
    ON cs.cs_warehouse_sk = w.w_warehouse_sk
JOIN web_sales ws
    ON ws.ws_sold_date_sk = d.d_date_sk
JOIN web_site ws_site
    ON ws.ws_web_site_sk = ws_site.web_site_sk
JOIN web_returns wr
    ON wr.wr_order_number = ws.ws_order_number
JOIN reason r
    ON wr.wr_reason_sk = r.r_reason_sk
LEFT JOIN inv_agg
    ON inv_agg.inv_warehouse_sk = w.w_warehouse_sk
   AND inv_agg.d_year = d.d_year
WHERE d.d_year = 2001
  AND cs.cs_quantity > 5
  AND p.p_discount_active = 'Y'
  AND ib.ib_upper_bound >= 150000
  AND hd.hd_buy_potential = '>10000'
GROUP BY
    c.c_customer_id,
    d.d_year,
    w.w_warehouse_name,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    hd.hd_buy_potential,
    inv_agg.total_qty_on_hand,
    hd.hd_vehicle_count,
    ws.ws_list_price,
    p.p_promo_name,
    r.r_reason_desc,
    ws_site.web_name
ORDER BY total_sales DESC
LIMIT 100
