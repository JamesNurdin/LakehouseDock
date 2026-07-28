WITH base AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        i.i_brand,
        i.i_item_id,
        ss.ss_quantity,
        ss.ss_net_profit,
        ss.ss_ext_sales_price,
        ws.ws_quantity,
        ws.ws_ext_sales_price,
        ws.ws_coupon_amt,
        wsite.web_name,
        wsite.web_state
    FROM date_dim AS d
    JOIN store_sales AS ss
        ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item AS i
        ON ss.ss_item_sk = i.i_item_sk
    JOIN web_sales AS ws
        ON ws.ws_sold_date_sk = d.d_date_sk
        AND ws.ws_item_sk = i.i_item_sk
    JOIN web_site AS wsite
        ON ws.ws_web_site_sk = wsite.web_site_sk
    WHERE d.d_year = 2001
      AND d.d_month_seq BETWEEN 1200 AND 1300
      AND d.d_weekend = 'N'
      AND i.i_wholesale_cost > 1.00
      AND i.i_units = 'Each'
      AND ss.ss_quantity >= 2
      AND ws.ws_coupon_amt = 0.00
      AND wsite.web_state = 'CA'
)
SELECT
    d_year,
    d_month_seq,
    i_brand,
    web_name,
    COUNT(DISTINCT i_item_id) AS distinct_items_sold,
    SUM(ss_ext_sales_price) AS total_store_sales,
    SUM(ws_ext_sales_price) AS total_web_sales,
    AVG(ss_net_profit) AS avg_store_net_profit,
    MIN(ws_coupon_amt) AS min_coupon_amt,
    MAX(ws_coupon_amt) AS max_coupon_amt
FROM base
GROUP BY d_year, d_month_seq, i_brand, web_name
ORDER BY total_store_sales DESC
LIMIT 100
