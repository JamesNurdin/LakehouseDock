WITH store_sales_agg AS (
    SELECT
        ss.ss_ticket_number,
        ss.ss_item_sk,
        ss.ss_sold_date_sk,
        ss.ss_store_sk,
        ss.ss_customer_sk,
        ss.ss_cdemo_sk,
        ss.ss_hdemo_sk,
        SUM(ss.ss_ext_sales_price) AS total_store_sales,
        SUM(ss.ss_quantity) AS total_store_qty
    FROM store_sales ss
    WHERE ss.ss_sold_date_sk IN (
        SELECT d_date_sk
        FROM date_dim
        WHERE d_year = 2001
    )
    GROUP BY
        ss.ss_ticket_number,
        ss.ss_item_sk,
        ss.ss_sold_date_sk,
        ss.ss_store_sk,
        ss.ss_customer_sk,
        ss.ss_cdemo_sk,
        ss.ss_hdemo_sk
),
non_returned_sales AS (
    SELECT ss_ticket_number
    FROM store_sales
    EXCEPT
    SELECT sr_ticket_number
    FROM store_returns
)
SELECT
    d.d_year,
    s.s_state,
    i.i_category,
    hd.hd_buy_potential,
    cd.cd_gender,
    cp.cp_department,
    COUNT(DISTINCT ss_agg.ss_ticket_number) AS num_transactions,
    SUM(ss_agg.total_store_sales) AS sum_store_sales,
    SUM(ws.ws_ext_sales_price) AS sum_web_sales,
    AVG(ss_agg.total_store_sales) AS avg_store_sales,
    CASE
        WHEN SUM(ss_agg.total_store_sales) > 10000 THEN 'High'
        ELSE 'Low'
    END AS sales_segment,
    (
        SELECT AVG(ws2.ws_ext_sales_price)
        FROM web_sales ws2
        JOIN date_dim d2 ON ws2.ws_sold_date_sk = d2.d_date_sk
        WHERE d2.d_year = 2001
    ) AS avg_web_sales_year,
    SUM(ss_agg.total_store_sales) - SUM(ws.ws_ext_sales_price) AS sales_vs_web_diff
FROM store_sales_agg ss_agg
JOIN date_dim d ON ss_agg.ss_sold_date_sk = d.d_date_sk
JOIN item i ON ss_agg.ss_item_sk = i.i_item_sk
JOIN store s ON ss_agg.ss_store_sk = s.s_store_sk
JOIN customer c ON ss_agg.ss_customer_sk = c.c_customer_sk
JOIN customer_demographics cd ON ss_agg.ss_cdemo_sk = cd.cd_demo_sk
JOIN household_demographics hd ON ss_agg.ss_hdemo_sk = hd.hd_demo_sk
LEFT JOIN store_returns sr ON ss_agg.ss_ticket_number = sr.sr_ticket_number
JOIN inventory inv ON i.i_item_sk = inv.inv_item_sk AND d.d_date_sk = inv.inv_date_sk
JOIN catalog_page cp ON d.d_date_sk = cp.cp_start_date_sk
JOIN web_page wp ON c.c_customer_sk = wp.wp_customer_sk AND d.d_date_sk = wp.wp_creation_date_sk
JOIN web_sales ws ON i.i_item_sk = ws.ws_item_sk AND d.d_date_sk = ws.ws_sold_date_sk
JOIN web_site we ON ws.ws_web_site_sk = we.web_site_sk AND d.d_date_sk = we.web_open_date_sk
WHERE
    d.d_year = 2001
    AND s.s_geography_class = 'Unknown'
    AND i.i_brand = 'Brand#45'
    AND hd.hd_income_band_sk = 12
    AND cd.cd_gender = 'F'
    AND inv.inv_quantity_on_hand > 0
    AND ss_agg.ss_ticket_number IN (SELECT ss_ticket_number FROM non_returned_sales)
GROUP BY
    d.d_year,
    s.s_state,
    i.i_category,
    hd.hd_buy_potential,
    cd.cd_gender,
    cp.cp_department
ORDER BY sum_store_sales DESC
LIMIT 100
