WITH sales_returns AS (
    SELECT
        ws.ws_order_number,
        ws.ws_net_profit,
        ws.ws_quantity,
        ws.ws_sold_date_sk,
        i.i_item_desc,
        p.p_promo_name,
        r.r_reason_desc,
        d.d_month_seq,
        regexp_extract(i.i_item_desc, '(\\d+)', 1) AS num_seq
    FROM tpcds.web_sales ws
    JOIN tpcds.item i
        ON ws.ws_item_sk = i.i_item_sk
    JOIN tpcds.promotion p
        ON ws.ws_promo_sk = p.p_promo_sk
    JOIN tpcds.date_dim d
        ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN tpcds.web_returns wr
        ON wr.wr_order_number = ws.ws_order_number
    JOIN tpcds.reason r
        ON wr.wr_reason_sk = r.r_reason_sk
    WHERE regexp_like(i.i_item_desc, '\\d{3}')
      AND r.r_reason_desc LIKE '%price%'
)
SELECT
    p_promo_name,
    d_month_seq AS month_seq,
    COUNT(DISTINCT ws_order_number) AS orders,
    SUM(ws_net_profit) AS total_profit,
    AVG(CAST(num_seq AS DOUBLE)) AS avg_extracted_number
FROM sales_returns
GROUP BY p_promo_name, d_month_seq
HAVING SUM(ws_net_profit) > 10000
ORDER BY total_profit DESC
LIMIT 100
