WITH cs_agg AS (
    SELECT
        cs_order_number,
        SUM(cs_ext_sales_price) AS total_cs_sales,
        COUNT(*) AS cnt_cs_sales
    FROM catalog_sales
    WHERE cs_sold_date_sk BETWEEN 2450900 AND 2451500
    GROUP BY cs_order_number
),
scalar_sub AS (
    SELECT AVG(total_cs_sales) AS avg_total_cs_sales FROM cs_agg
),
ss_sr AS (
    SELECT
        ss.*,
        sr.*
    FROM store_sales ss
    FULL OUTER JOIN store_returns sr
        ON ss.ss_ticket_number = sr.sr_ticket_number
),
ws_wr AS (
    SELECT
        ws.*,
        wr.*
    FROM web_sales ws
    FULL OUTER JOIN web_returns wr
        ON ws.ws_order_number = wr.wr_order_number
)
SELECT
    cp.cp_department,
    w.w_state,
    ca_bill.ca_state AS bill_state,
    r.r_reason_desc,
    SUM(cs_agg.total_cs_sales) AS dept_state_sales,
    COUNT(DISTINCT cs.cs_order_number) AS distinct_orders,
    AVG(ss.ss_net_profit) AS avg_store_profit,
    SUM(CASE WHEN r.r_reason_desc = 'Damaged' THEN cr.cr_return_amount ELSE 0 END) AS damaged_return_total,
    ROW_NUMBER() OVER (PARTITION BY cp.cp_department ORDER BY SUM(cs_agg.total_cs_sales) DESC) AS dept_sales_rank
FROM cs_agg
JOIN catalog_sales cs
    ON cs_agg.cs_order_number = cs.cs_order_number
JOIN catalog_page cp
    ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN warehouse w
    ON cs.cs_warehouse_sk = w.w_warehouse_sk
JOIN customer_address ca_bill
    ON cs.cs_bill_addr_sk = ca_bill.ca_address_sk
JOIN customer_address ca_ship
    ON cs.cs_ship_addr_sk = ca_ship.ca_address_sk
JOIN customer_demographics cd_bill
    ON cs.cs_bill_cdemo_sk = cd_bill.cd_demo_sk
JOIN customer_demographics cd_ship
    ON cs.cs_ship_cdemo_sk = cd_ship.cd_demo_sk
LEFT JOIN catalog_returns cr
    ON cr.cr_order_number = cs.cs_order_number
LEFT JOIN reason r
    ON cr.cr_reason_sk = r.r_reason_sk
-- connect store side through customer dimension
LEFT JOIN ss_sr ssr
    ON ssr.ss_cdemo_sk = cd_bill.cd_demo_sk
LEFT JOIN store_sales ss
    ON ssr.ss_ticket_number = ss.ss_ticket_number
LEFT JOIN store_returns sr
    ON ssr.sr_ticket_number = sr.sr_ticket_number
-- connect web side through customer dimension
LEFT JOIN ws_wr wswr
    ON wswr.ws_bill_cdemo_sk = cd_bill.cd_demo_sk
LEFT JOIN web_sales ws
    ON wswr.ws_order_number = ws.ws_order_number
LEFT JOIN web_returns wr
    ON wswr.wr_order_number = wr.wr_order_number
JOIN web_page wp
    ON ws.ws_web_page_sk = wp.wp_web_page_sk
JOIN web_site webs
    ON ws.ws_web_site_sk = webs.web_site_sk
WHERE
    cp.cp_department = 'Electronics'
    AND w.w_state = 'CA'
    AND ca_bill.ca_country = 'United States'
    AND cr.cr_return_quantity > 0
    AND ws.ws_quantity > 2
    AND cs_agg.total_cs_sales > (SELECT avg_total_cs_sales FROM scalar_sub)
GROUP BY
    cp.cp_department,
    w.w_state,
    ca_bill.ca_state,
    r.r_reason_desc
ORDER BY dept_state_sales DESC
LIMIT 100
