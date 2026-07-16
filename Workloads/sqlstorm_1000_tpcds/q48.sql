WITH unified_sales AS (
    SELECT
        ss_sold_date_sk AS sold_date_sk,
        ss_store_sk AS store_sk,
        ss_item_sk AS item_sk,
        ss_net_paid AS net_paid,
        ss_net_profit AS net_profit,
        'store' AS channel
    FROM store_sales
    UNION ALL
    SELECT
        cs_sold_date_sk,
        cs_call_center_sk,
        cs_item_sk,
        cs_net_paid,
        cs_net_profit,
        'catalog'
    FROM catalog_sales
    UNION ALL
    SELECT
        ws_sold_date_sk,
        ws_warehouse_sk,
        ws_item_sk,
        ws_net_paid,
        ws_net_profit,
        'web'
    FROM web_sales
)
SELECT
    d.d_year,
    d.d_month_seq,
    us.channel,
    i.i_category,
    sum(us.net_paid) AS total_paid,
    sum(us.net_profit) AS total_profit,
    count(*) AS sales_count
FROM unified_sales us
JOIN date_dim d ON us.sold_date_sk = d.d_date_sk
JOIN item i ON us.item_sk = i.i_item_sk
WHERE d.d_year BETWEEN 2000 AND 2002
GROUP BY d.d_year, d.d_month_seq, us.channel, i.i_category
ORDER BY total_profit DESC
LIMIT 100
