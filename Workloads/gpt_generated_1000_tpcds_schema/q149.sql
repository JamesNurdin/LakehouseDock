WITH brand_sales AS (
    SELECT
        ws.ws_web_site_sk,
        i.i_brand,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        SUM(ws.ws_net_profit) AS total_profit,
        COUNT(*) AS order_cnt
    FROM
        web_sales ws TABLESAMPLE BERNOULLI (10)
        JOIN item i
            ON ws.ws_item_sk = i.i_item_sk
        JOIN web_site w
            ON ws.ws_web_site_sk = w.web_site_sk
    WHERE
        ws.ws_coupon_amt > 100
        AND ws.ws_ext_ship_cost < 2000
        AND w.web_mkt_id IN (2, 3, 4, 5)
        AND i.i_rec_start_date >= DATE '1999-01-01'
    GROUP BY
        ws.ws_web_site_sk,
        i.i_brand
)
SELECT
    w.web_name,
    AVG(bs.total_sales) AS avg_brand_sales,
    SUM(bs.total_profit) AS site_total_profit,
    COUNT(DISTINCT bs.i_brand) AS distinct_brand_cnt
FROM
    brand_sales bs
    JOIN web_site w
        ON bs.ws_web_site_sk = w.web_site_sk
GROUP BY
    w.web_name
HAVING
    SUM(bs.total_profit) > 10000
    AND AVG(bs.total_sales) > 5000
ORDER BY
    avg_brand_sales DESC
LIMIT 100
