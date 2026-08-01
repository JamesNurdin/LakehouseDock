WITH base AS (
    SELECT
        d.d_year,
        i.i_brand,
        sm.sm_code,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        SUM(cs.cs_net_profit) AS total_profit,
        COUNT(DISTINCT cs.cs_order_number) AS order_cnt
    FROM tpcds.date_dim d
    JOIN tpcds.catalog_sales cs
        ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN tpcds.item i
        ON cs.cs_item_sk = i.i_item_sk
    JOIN tpcds.ship_mode sm
        ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN tpcds.household_demographics hd
        ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN tpcds.customer_address ca
        ON cs.cs_bill_addr_sk = ca.ca_address_sk
    JOIN tpcds.inventory inv
        ON inv.inv_item_sk = i.i_item_sk
        AND inv.inv_date_sk = d.d_date_sk
    JOIN tpcds.web_sales ws
        ON ws.ws_item_sk = i.i_item_sk
    JOIN tpcds.web_page wp
        ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN tpcds.web_site wsite
        ON ws.ws_web_site_sk = wsite.web_site_sk
    JOIN tpcds.web_returns wr
        ON wr.wr_order_number = ws.ws_order_number
    JOIN tpcds.store_returns sr
        ON sr.sr_item_sk = i.i_item_sk
    JOIN tpcds.reason r
        ON sr.sr_reason_sk = r.r_reason_sk
    WHERE d.d_date BETWEEN DATE '2022-01-01' AND DATE '2022-12-31'
      AND i.i_brand = 'Brand#12'
      AND sm.sm_code = 'AIR'
      AND hd.hd_vehicle_count > 0
    GROUP BY GROUPING SETS (
        (d.d_year, i.i_brand, sm.sm_code),
        (d.d_year, i.i_brand),
        (d.d_year),
        ()
    )
)
SELECT
    d_year,
    i_brand,
    sm_code,
    total_sales,
    total_profit,
    order_cnt,
    total_sales / NULLIF(order_cnt, 0) AS avg_sales_per_order,
    SUM(total_sales) OVER () AS grand_total_sales,
    AVG(total_sales) OVER () AS avg_sales_per_group
FROM base
WHERE total_sales > 10000
ORDER BY d_year, i_brand, sm_code
