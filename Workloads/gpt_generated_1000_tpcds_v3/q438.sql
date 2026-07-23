WITH sales_data AS (
    SELECT
        ss.ss_sold_date_sk,
        ss.ss_item_sk,
        ss.ss_quantity,
        ss.ss_ext_sales_price,
        ss.ss_ext_discount_amt,
        ss.ss_net_profit,
        i.i_item_id,
        i.i_brand,
        i.i_manufact,
        i.i_container,
        d.d_year,
        d.d_month_seq,
        cc.cc_name,
        cc.cc_state,
        ws.web_name,
        ws.web_country,
        inv.inv_quantity_on_hand
    FROM store_sales ss
    INNER JOIN date_dim d
        ON ss.ss_sold_date_sk = d.d_date_sk
    INNER JOIN item i
        ON ss.ss_item_sk = i.i_item_sk
    INNER JOIN inventory inv
        ON inv.inv_item_sk = i.i_item_sk
        AND inv.inv_date_sk = d.d_date_sk
    INNER JOIN call_center cc
        ON cc.cc_open_date_sk = d.d_date_sk
    INNER JOIN web_site ws
        ON ws.web_open_date_sk = d.d_date_sk
    WHERE
        d.d_year = 2001
        AND i.i_manufact = 'esecallyable'
        AND i.i_container = 'Unknown'
        AND cc.cc_state = 'CA'
        AND ws.web_country = 'United States'
        AND ss.ss_quantity > 5
        AND inv.inv_quantity_on_hand >= 100
        AND EXISTS (
            SELECT 1 FROM web_page wp
            WHERE wp.wp_creation_date_sk = d.d_date_sk
              AND wp.wp_type = 'product'
              AND wp.wp_char_count > 1000
        )
)
SELECT
    cc_name,
    web_name,
    i_brand,
    d_year,
    d_month_seq,
    SUM(ss_ext_sales_price) AS total_sales,
    SUM(ss_net_profit) AS total_profit,
    AVG(ss_ext_discount_amt) AS avg_discount,
    COUNT(DISTINCT i_item_id) AS distinct_items,
    MIN(ss_quantity) AS min_quantity,
    MAX(ss_quantity) AS max_quantity
FROM sales_data
GROUP BY
    cc_name,
    web_name,
    i_brand,
    d_year,
    d_month_seq
HAVING
    SUM(ss_net_profit) > 10000
ORDER BY
    total_profit DESC
LIMIT 100
