WITH sampled_cs AS (
    SELECT *
    FROM catalog_sales
    TABLESAMPLE BERNOULLI (5)  -- sample 5% of catalog_sales
),
orders_no_ret AS (
    SELECT cs_order_number
    FROM sampled_cs
    EXCEPT
    SELECT cr_order_number FROM catalog_returns
),
filtered_cs AS (
    SELECT cs.*
    FROM sampled_cs cs
    JOIN orders_no_ret on cs.cs_order_number = orders_no_ret.cs_order_number
    WHERE cs.cs_quantity > 5
      AND cs.cs_list_price BETWEEN 20 AND 300
)
SELECT
    d.d_year,
    s.s_state,
    w.w_warehouse_name,
    ib.ib_lower_bound,
    SUM(cs.cs_ext_sales_price) AS catalog_sales_amount,
    SUM(ss.ss_ext_sales_price) AS store_sales_amount,
    SUM(ws.ws_ext_sales_price) AS web_sales_amount,
    SUM(inv.inv_quantity_on_hand) AS inventory_on_hand,
    ROW_NUMBER() OVER (PARTITION BY d.d_year ORDER BY SUM(cs.cs_ext_sales_price) DESC) AS sales_rank
FROM date_dim d
LEFT JOIN filtered_cs cs                     ON cs.cs_sold_date_sk = d.d_date_sk
LEFT JOIN catalog_page cp                     ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
LEFT JOIN household_demographics hd           ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
LEFT JOIN income_band ib                     ON hd.hd_income_band_sk = ib.ib_income_band_sk
LEFT JOIN ship_mode sm                       ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
LEFT JOIN warehouse w                        ON cs.cs_warehouse_sk = w.w_warehouse_sk
LEFT JOIN catalog_returns cr                 ON cr.cr_order_number = cs.cs_order_number
LEFT JOIN reason r                           ON cr.cr_reason_sk = r.r_reason_sk
LEFT JOIN store_sales ss                     ON ss.ss_sold_date_sk = d.d_date_sk
LEFT JOIN store s                            ON ss.ss_store_sk = s.s_store_sk
LEFT JOIN web_sales ws                       ON ws.ws_sold_date_sk = d.d_date_sk
LEFT JOIN web_page wp                        ON ws.ws_web_page_sk = wp.wp_web_page_sk
LEFT JOIN web_site web                       ON ws.ws_web_site_sk = web.web_site_sk
LEFT JOIN inventory inv                      ON inv.inv_date_sk = d.d_date_sk AND inv.inv_warehouse_sk = w.w_warehouse_sk
WHERE d.d_year BETWEEN 1999 AND 2001
  AND ib.ib_upper_bound >= 50000
  AND r.r_reason_desc LIKE '%service%'
  AND sm.sm_type = 'AIR'
  AND w.w_state = 'CA'
GROUP BY GROUPING SETS (
    (d.d_year, s.s_state),
    (d.d_year, w.w_warehouse_name, ib.ib_lower_bound),
    (d.d_year)
)
HAVING SUM(cs.cs_ext_sales_price) > 10000
ORDER BY d.d_year, sales_rank
LIMIT 100
