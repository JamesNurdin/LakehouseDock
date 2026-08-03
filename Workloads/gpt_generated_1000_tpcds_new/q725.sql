WITH inv_agg AS (
    SELECT
        inv.inv_item_sk,
        inv.inv_date_sk,
        SUM(inv.inv_quantity_on_hand) AS total_on_hand
    FROM inventory inv
    GROUP BY inv.inv_item_sk, inv.inv_date_sk
),
joined AS (
    SELECT
        d.d_year,
        cc.cc_market_manager,
        i.i_category,
        i.i_item_id,
        cs.cs_ext_sales_price,
        ws.ws_ext_sales_price,
        sr.sr_return_amt,
        inv_agg.total_on_hand,
        t.t_meal_time,
        cd.cd_gender,
        cust.c_customer_id
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN time_dim t ON cs.cs_sold_time_sk = t.t_time_sk
    JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN customer cust ON cs.cs_bill_customer_sk = cust.c_customer_sk
    LEFT JOIN inventory inv ON i.i_item_sk = inv.inv_item_sk AND d.d_date_sk = inv.inv_date_sk
    LEFT JOIN inv_agg ON i.i_item_sk = inv_agg.inv_item_sk AND d.d_date_sk = inv_agg.inv_date_sk
    LEFT JOIN store_returns sr ON i.i_item_sk = sr.sr_item_sk AND d.d_date_sk = sr.sr_returned_date_sk
    LEFT JOIN web_sales ws ON i.i_item_sk = ws.ws_item_sk AND d.d_date_sk = ws.ws_sold_date_sk
    LEFT JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    WHERE d.d_year BETWEEN 2001 AND 2002
      AND cc.cc_mkt_id IN (1, 3, 5)
      AND i.i_current_price BETWEEN 20 AND 100
      AND t.t_meal_time IN ('lunch', 'dinner')
      AND cd.cd_gender = 'M'
),
agg AS (
    SELECT
        d_year,
        cc_market_manager,
        i_category,
        COUNT(DISTINCT i_item_id) AS distinct_items_sold,
        SUM(cs_ext_sales_price) AS total_catalog_sales,
        SUM(ws_ext_sales_price) AS total_web_sales,
        SUM(sr_return_amt) AS total_returns,
        SUM(total_on_hand) AS total_inventory_on_hand,
        CASE WHEN SUM(cs_ext_sales_price) > 50000 THEN 'High' ELSE 'Low' END AS sales_level
    FROM joined
    GROUP BY ROLLUP(d_year, cc_market_manager, i_category)
)
SELECT
    d_year,
    cc_market_manager,
    i_category,
    distinct_items_sold,
    total_catalog_sales,
    total_web_sales,
    total_returns,
    total_inventory_on_hand,
    sales_level,
    LAG(total_catalog_sales) OVER (PARTITION BY cc_market_manager ORDER BY d_year) AS prev_year_catalog_sales
FROM agg
ORDER BY d_year NULLS LAST,
         cc_market_manager NULLS LAST,
         i_category NULLS LAST
LIMIT 100
