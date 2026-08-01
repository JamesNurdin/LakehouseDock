WITH
    date_sample AS (
        SELECT *
        FROM date_dim
        TABLESAMPLE BERNOULLI (10)
        WHERE d_year = 2000
    ),
    call_center_filt AS (
        SELECT *
        FROM call_center
        WHERE cc_name LIKE '%Central%'
          AND cc_gmt_offset > -5
    ),
    store_filt AS (
        SELECT *
        FROM store
        WHERE s_state = 'CA'
          AND s_gmt_offset IS NOT NULL
    ),
    item_filt AS (
        SELECT *
        FROM item
        WHERE i_brand = 'Brand#12'
    ),
    intersect_items AS (
        SELECT ss_item_sk AS item_sk
        FROM store_sales
        INTERSECT
        SELECT ws_item_sk
        FROM web_sales
    ),
    store_sales_full AS (
        SELECT ss.*, i.i_item_id, i.i_brand, i.i_current_price
        FROM store_sales ss
        JOIN item i ON ss.ss_item_sk = i.i_item_sk
        FULL OUTER JOIN store s ON ss.ss_store_sk = s.s_store_sk
        WHERE ss.ss_item_sk IN (SELECT item_sk FROM intersect_items)
    ),
    store_returns_filt AS (
        SELECT *
        FROM store_returns
        WHERE sr_return_amt_inc_tax > 1000
    ),
    web_page_filt AS (
        SELECT *
        FROM web_page
        WHERE wp_type = 'Content'
    ),
    web_sales_filt AS (
        SELECT *
        FROM web_sales
        WHERE ws_sales_price > 100
    )
SELECT
    d.d_date,
    cc.cc_name,
    s.s_store_name,
    i.i_item_id,
    ws.ws_order_number,
    ws.ws_sales_price,
    CASE WHEN ws.ws_net_profit > 0 THEN 'Profitable' ELSE 'Loss' END AS profit_flag,
    RANK() OVER (PARTITION BY s.s_store_name ORDER BY ws.ws_net_profit DESC) AS profit_rank,
    SUM(ws.ws_net_profit) OVER (PARTITION BY s.s_store_name ORDER BY d.d_date ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_profit
FROM date_sample d
LEFT JOIN call_center_filt cc ON cc.cc_open_date_sk = d.d_date_sk
LEFT JOIN store_filt s ON s.s_closed_date_sk = d.d_date_sk
LEFT JOIN store_sales_full ss ON ss.ss_sold_date_sk = d.d_date_sk
LEFT JOIN store_returns_filt sr ON sr.sr_returned_date_sk = d.d_date_sk
    AND sr.sr_store_sk = s.s_store_sk
    AND sr.sr_item_sk = ss.ss_item_sk
LEFT JOIN item_filt i ON i.i_item_sk = ss.ss_item_sk
LEFT JOIN web_page_filt wp ON wp.wp_creation_date_sk = d.d_date_sk
LEFT JOIN web_sales_filt ws ON ws.ws_sold_date_sk = d.d_date_sk
    AND ws.ws_item_sk = i.i_item_sk
    AND ws.ws_web_page_sk = wp.wp_web_page_sk
WHERE ss.ss_quantity IS NOT NULL
ORDER BY d.d_date DESC, profit_rank
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY
