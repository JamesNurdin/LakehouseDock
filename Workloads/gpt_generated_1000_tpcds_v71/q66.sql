WITH sales_ret AS (
    SELECT
        i.i_item_sk,
        i.i_product_name,
        ws.ws_web_site_sk AS web_site_sk,
        ws.ws_web_page_sk AS web_page_sk,
        wsite.web_name,
        wsite.web_state,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        SUM(ws.ws_net_profit) AS total_profit,
        COUNT(*) AS sales_cnt,
        SUM(COALESCE(wr.wr_return_amt, 0)) AS total_return_amt,
        COUNT(wr.wr_return_quantity) AS return_cnt
    FROM
        web_sales ws
        JOIN item i
            ON ws.ws_item_sk = i.i_item_sk
        JOIN web_page wp
            ON ws.ws_web_page_sk = wp.wp_web_page_sk
        JOIN web_site wsite
            ON ws.ws_web_site_sk = wsite.web_site_sk
        LEFT JOIN web_returns wr
            ON wr.wr_item_sk = ws.ws_item_sk
            AND wr.wr_order_number = ws.ws_order_number
            AND wr.wr_web_page_sk = wp.wp_web_page_sk
    WHERE
        i.i_current_price BETWEEN 20 AND 200
        AND wp.wp_link_count >= 5
        AND ws.ws_quantity > 1
    GROUP BY
        i.i_item_sk,
        i.i_product_name,
        ws.ws_web_site_sk,
        ws.ws_web_page_sk,
        wsite.web_name,
        wsite.web_state
)
SELECT
    s.i_item_sk,
    s.i_product_name,
    s.web_name,
    s.web_state,
    s.total_sales,
    s.total_profit,
    s.total_return_amt,
    (s.total_profit - s.total_return_amt) AS net_contribution,
    RANK() OVER (PARTITION BY s.web_name ORDER BY s.total_profit DESC) AS profit_rank
FROM
    sales_ret s
WHERE
    s.total_sales > 1000
    AND s.total_profit > 0
    AND s.return_cnt < s.sales_cnt
ORDER BY
    net_contribution DESC
LIMIT 100
