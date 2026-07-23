WITH sales AS (
    SELECT
        ss.ss_sold_date_sk AS sold_date_sk,
        ss.ss_store_sk AS store_sk,
        ss.ss_item_sk AS item_sk,
        ss.ss_customer_sk AS customer_sk,
        ss.ss_hdemo_sk AS hdemo_sk,
        ss.ss_addr_sk AS addr_sk,
        ss.ss_quantity AS quantity,
        ss.ss_net_paid AS net_paid,
        ss.ss_ext_discount_amt AS discount_amt,
        ss.ss_net_profit AS net_profit
    FROM store_sales ss
    UNION ALL
    SELECT
        ws.ws_sold_date_sk AS sold_date_sk,
        NULL AS store_sk,
        ws.ws_item_sk AS item_sk,
        ws.ws_bill_customer_sk AS customer_sk,
        ws.ws_bill_hdemo_sk AS hdemo_sk,
        ws.ws_bill_addr_sk AS addr_sk,
        ws.ws_quantity AS quantity,
        ws.ws_net_paid AS net_paid,
        ws.ws_ext_discount_amt AS discount_amt,
        ws.ws_net_profit AS net_profit
    FROM web_sales ws
)
SELECT
    COALESCE(s.s_store_name, 'WEB') AS store_name,
    d.d_year,
    d.d_month_seq,
    i.i_category,
    COUNT(*) AS sales_transactions,
    SUM(sales.quantity) AS total_quantity,
    SUM(sales.net_paid) AS total_net_paid,
    AVG(sales.discount_amt) AS avg_discount,
    SUM(sales.net_profit) AS total_net_profit,
    CASE WHEN SUM(sales.net_profit) > 0 THEN 'Profitable' ELSE 'Loss' END AS profit_flag
FROM sales
JOIN date_dim d ON sales.sold_date_sk = d.d_date_sk
JOIN item i ON sales.item_sk = i.i_item_sk
JOIN customer c ON sales.customer_sk = c.c_customer_sk
JOIN household_demographics hd ON sales.hdemo_sk = hd.hd_demo_sk
JOIN customer_address ca ON sales.addr_sk = ca.ca_address_sk
LEFT JOIN store s ON sales.store_sk = s.s_store_sk
WHERE
    d.d_year = 1998
    AND d.d_month_seq BETWEEN 1 AND 12
    AND c.c_birth_year BETWEEN 1940 AND 1960
    AND s.s_manager = 'Brian Norris'
    AND ca.ca_state = 'CA'
    AND i.i_category = 'Electronics'
    AND EXISTS (
        SELECT 1
        FROM catalog_page cp
        WHERE cp.cp_start_date_sk = d.d_date_sk
          AND cp.cp_type = 'Promotional'
    )
GROUP BY
    COALESCE(s.s_store_name, 'WEB'),
    d.d_year,
    d.d_month_seq,
    i.i_category
ORDER BY
    total_net_paid DESC,
    store_name
LIMIT 100
