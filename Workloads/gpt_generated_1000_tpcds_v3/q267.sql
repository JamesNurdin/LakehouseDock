WITH unified_returns AS (
    SELECT
        sr.sr_returned_date_sk AS date_sk,
        sr.sr_item_sk AS item_sk,
        sr.sr_hdemo_sk AS hd_demo_sk,
        sr.sr_addr_sk AS addr_sk,
        sr.sr_return_quantity AS quantity,
        sr.sr_net_loss AS net_amount,
        'store' AS source
    FROM store_returns sr
    UNION ALL
    SELECT
        ws.ws_sold_date_sk AS date_sk,
        ws.ws_item_sk AS item_sk,
        ws.ws_bill_hdemo_sk AS hd_demo_sk,
        ws.ws_bill_addr_sk AS addr_sk,
        ws.ws_quantity AS quantity,
        ws.ws_net_profit AS net_amount,
        'web' AS source
    FROM web_sales ws
    UNION ALL
    SELECT
        wr.wr_returned_date_sk AS date_sk,
        wr.wr_item_sk AS item_sk,
        wr.wr_refunded_hdemo_sk AS hd_demo_sk,
        wr.wr_refunded_addr_sk AS addr_sk,
        wr.wr_return_quantity AS quantity,
        wr.wr_net_loss AS net_amount,
        'web_return' AS source
    FROM web_returns wr
)
SELECT
    d.d_year,
    i.i_category,
    hd.hd_buy_potential,
    ib.ib_lower_bound,
    ca.ca_state,
    s.s_store_name,
    cp.cp_department,
    wp.wp_type,
    src.source,
    COUNT(DISTINCT src.item_sk) AS distinct_items,
    SUM(src.quantity) AS total_quantity,
    SUM(src.net_amount) AS total_amount,
    AVG(src.net_amount) AS avg_amount,
    MIN(src.net_amount) AS min_amount,
    MAX(src.net_amount) AS max_amount,
    CASE
        WHEN SUM(src.net_amount) > 100000 THEN 'High'
        WHEN SUM(src.net_amount) > 50000 THEN 'Medium'
        ELSE 'Low'
    END AS revenue_category
FROM unified_returns src
JOIN date_dim d ON src.date_sk = d.d_date_sk
JOIN item i ON src.item_sk = i.i_item_sk
JOIN household_demographics hd ON src.hd_demo_sk = hd.hd_demo_sk
JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
JOIN customer_address ca ON src.addr_sk = ca.ca_address_sk
LEFT JOIN store s ON s.s_closed_date_sk = d.d_date_sk
LEFT JOIN catalog_page cp ON cp.cp_start_date_sk = d.d_date_sk
LEFT JOIN web_page wp ON wp.wp_creation_date_sk = d.d_date_sk
WHERE
    d.d_year = 2002
    AND i.i_current_price BETWEEN 10 AND 1000
    AND ca.ca_state IN ('CA', 'TX', 'NY')
    AND hd.hd_buy_potential IN ('HIGH', 'MEDIUM')
    AND ib.ib_upper_bound <= 100000
    AND cp.cp_department = 'Electronics'
GROUP BY
    d.d_year,
    i.i_category,
    hd.hd_buy_potential,
    ib.ib_lower_bound,
    ca.ca_state,
    s.s_store_name,
    cp.cp_department,
    wp.wp_type,
    src.source
ORDER BY total_amount DESC
LIMIT 100
