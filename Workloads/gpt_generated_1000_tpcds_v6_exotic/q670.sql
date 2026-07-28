WITH sales_agg AS (
    SELECT
        s.s_store_id,
        s.s_store_name,
        d.d_year,
        SUM(cs.cs_ext_sales_price)                     AS total_catalog_sales,
        SUM(ws.ws_ext_sales_price)                     AS total_web_sales,
        COUNT(DISTINCT i.i_item_id)                    AS distinct_items,
        COUNT(DISTINCT r.r_reason_desc)                AS distinct_reasons
    FROM catalog_sales cs
    JOIN date_dim d               ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN time_dim t               ON cs.cs_sold_time_sk = t.t_time_sk
    JOIN call_center cc           ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN ship_mode sm             ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN item i                   ON cs.cs_item_sk = i.i_item_sk
    JOIN customer cu              ON cs.cs_bill_customer_sk = cu.c_customer_sk
    JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN store_returns sr         ON sr.sr_item_sk = i.i_item_sk
    JOIN store s                  ON sr.sr_store_sk = s.s_store_sk
    JOIN reason r                 ON sr.sr_reason_sk = r.r_reason_sk
    JOIN inventory inv            ON inv.inv_item_sk = i.i_item_sk AND inv.inv_date_sk = d.d_date_sk
    JOIN web_sales ws             ON ws.ws_item_sk = i.i_item_sk AND ws.ws_sold_date_sk = d.d_date_sk
    JOIN web_page wp              ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN web_returns wr          ON wr.wr_order_number = ws.ws_order_number
    WHERE d.d_year = 2001
      AND s.s_country = 'United States'
      AND i.i_brand = 'Brand#12'
      AND hd.hd_buy_potential = '5001-10000'
      AND cs.cs_quantity > 2
    GROUP BY s.s_store_id, s.s_store_name, d.d_year
),
final_agg AS (
    SELECT
        s_store_id,
        s_store_name,
        d_year,
        total_catalog_sales,
        total_web_sales,
        distinct_items,
        distinct_reasons,
        (total_catalog_sales + total_web_sales) AS total_sales
    FROM sales_agg
    WHERE (total_catalog_sales + total_web_sales) > 10000
)
SELECT
    s_store_id,
    s_store_name,
    d_year,
    total_catalog_sales,
    total_web_sales,
    total_sales,
    distinct_items,
    distinct_reasons,
    AVG(total_sales) OVER (PARTITION BY d_year)            AS avg_sales_by_year,
    ROW_NUMBER() OVER (PARTITION BY d_year ORDER BY total_sales DESC) AS sales_rank
FROM final_agg
ORDER BY d_year DESC, total_sales DESC
LIMIT 100
