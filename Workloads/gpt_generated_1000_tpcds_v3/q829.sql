WITH sales_by_promo AS (
    SELECT
        ws.ws_promo_sk AS promo_sk,
        dd_sold.d_fy_quarter_seq AS fy_quarter_seq,
        SUM(ws.ws_net_profit) AS net_profit,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(*) AS order_cnt
    FROM web_sales ws
    JOIN date_dim dd_sold
        ON ws.ws_sold_date_sk = dd_sold.d_date_sk
    JOIN promotion p
        ON ws.ws_promo_sk = p.p_promo_sk
    WHERE dd_sold.d_fy_year = 1915
    GROUP BY ws.ws_promo_sk, dd_sold.d_fy_quarter_seq
)
SELECT
    p.p_promo_name,
    s.fy_quarter_seq,
    s.net_profit,
    s.total_sales,
    CASE
        WHEN s.net_profit > 0 THEN 'POSITIVE'
        WHEN s.net_profit = 0 THEN 'ZERO'
        ELSE 'NEGATIVE'
    END AS profit_category,
    regexp_extract(p.p_promo_name, '(\\d+)', 1) AS promo_number,
    CASE WHEN regexp_like(p.p_promo_name, '(?i)sale') THEN 'HAS_SALE' ELSE 'NO_SALE' END AS sale_flag,
    CONCAT(p.p_promo_name, '_Q', CAST(s.fy_quarter_seq AS varchar)) AS promo_quarter_key,
    SUBSTRING(p.p_promo_name, 1, 5) AS promo_name_prefix
FROM sales_by_promo s
JOIN promotion p
    ON s.promo_sk = p.p_promo_sk
JOIN date_dim d_start
    ON p.p_start_date_sk = d_start.d_date_sk
WHERE
    regexp_like(p.p_promo_name, '^Promo')
    AND p.p_purpose LIKE '%Unknown%'
    AND d_start.d_fy_year = 1915
GROUP BY
    p.p_promo_name,
    s.fy_quarter_seq,
    s.net_profit,
    s.total_sales
HAVING
    s.total_sales > 1000
ORDER BY
    s.net_profit DESC
