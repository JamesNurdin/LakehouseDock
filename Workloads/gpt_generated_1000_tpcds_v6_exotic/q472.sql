WITH sales_agg AS (
    SELECT
        cp.cp_catalog_page_id,
        i.i_brand,
        hd.hd_buy_potential,
        SUM(cs.cs_net_paid) AS total_sales,
        SUM(cr.cr_return_amount) AS total_returns,
        SUM(ws.ws_net_profit) AS total_web_profit,
        COUNT(DISTINCT cs.cs_order_number) AS orders_cnt
    FROM catalog_sales cs
    JOIN time_dim td
        ON cs.cs_sold_time_sk = td.t_time_sk
    JOIN catalog_page cp
        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN warehouse w
        ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN item i
        ON cs.cs_item_sk = i.i_item_sk
    JOIN household_demographics hd
        ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN catalog_returns cr
        ON cr.cr_order_number = cs.cs_order_number
       AND cr.cr_item_sk = cs.cs_item_sk
    JOIN inventory inv
        ON inv.inv_item_sk = i.i_item_sk
       AND inv.inv_warehouse_sk = w.w_warehouse_sk
    JOIN web_sales ws
        ON ws.ws_sold_time_sk = td.t_time_sk
       AND ws.ws_item_sk = i.i_item_sk
       AND ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN web_page wp
        ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN web_site site
        ON ws.ws_web_site_sk = site.web_site_sk
    WHERE hd.hd_dep_count = 2
      AND cp.cp_type = 'Promotional'
      AND i.i_current_price > 100
    GROUP BY cp.cp_catalog_page_id, i.i_brand, hd.hd_buy_potential
    HAVING SUM(cs.cs_net_paid) > 10000
)
SELECT
    cp_catalog_page_id,
    i_brand,
    hd_buy_potential,
    total_sales,
    total_returns,
    total_web_profit,
    orders_cnt,
    ROW_NUMBER() OVER (PARTITION BY i_brand ORDER BY total_sales DESC) AS brand_sales_rank,
    CASE
        WHEN total_sales > 50000 THEN 'High'
        WHEN total_sales > 20000 THEN 'Medium'
        ELSE 'Low'
    END AS sales_category
FROM sales_agg
ORDER BY total_sales DESC
LIMIT 100
