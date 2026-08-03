WITH grp AS (
    SELECT 1 AS grp UNION ALL SELECT 2 UNION ALL SELECT 3
)
SELECT
    s.s_store_name,
    i.i_category,
    we.web_name,
    hd.hd_income_band_sk,
    grp.grp,
    COUNT(DISTINCT ss.ss_ticket_number) AS num_sales,
    SUM(ss.ss_ext_sales_price) AS total_sales,
    AVG(CASE WHEN ss.ss_coupon_amt > 0 THEN ss.ss_ext_sales_price END) AS avg_discounted_sales,
    SUM(COALESCE(sr.sr_return_amt, 0)) AS total_returns,
    SUM(COALESCE(ws.ws_net_profit, 0)) AS total_web_profit,
    MIN(ss.ss_sold_date_sk) AS first_sale_date_sk,
    MAX(ss.ss_sold_date_sk) AS last_sale_date_sk
FROM
    store_sales ss
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    FULL OUTER JOIN store_returns sr ON sr.sr_ticket_number = ss.ss_ticket_number
    JOIN web_sales ws ON ws.ws_item_sk = i.i_item_sk
        AND ws.ws_bill_cdemo_sk = cd.cd_demo_sk
    JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN web_site we ON ws.ws_web_site_sk = we.web_site_sk
    CROSS JOIN grp
WHERE
    i.i_current_price BETWEEN 10 AND 100
    AND cd.cd_gender = 'M'
    AND hd.hd_vehicle_count >= 1
GROUP BY
    s.s_store_name,
    i.i_category,
    we.web_name,
    hd.hd_income_band_sk,
    grp.grp
ORDER BY
    total_sales DESC
LIMIT 100
