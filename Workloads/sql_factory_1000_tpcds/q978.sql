WITH daily_metrics AS (
    SELECT
        d.d_date,
        s.s_store_name,
        wsite.web_name,
        SUM(ws.ws_net_paid) AS total_net_paid,
        SUM(ws.ws_ext_discount_amt) AS total_discount_amt,
        SUM(ws.ws_ext_sales_price) AS total_sales_price
    FROM store s
    JOIN date_dim d ON s.s_closed_date_sk = d.d_date_sk
    JOIN web_sales ws ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN web_site wsite ON ws.ws_web_site_sk = wsite.web_site_sk
    GROUP BY d.d_date, s.s_store_name, wsite.web_name
)
SELECT
    dm.d_date,
    dm.s_store_name,
    dm.web_name,
    dm.total_net_paid,
    CASE
        WHEN dm.total_sales_price = 0 THEN 0
        ELSE dm.total_discount_amt / dm.total_sales_price
    END AS overall_discount_ratio,
    CASE
        WHEN (CASE WHEN dm.total_sales_price = 0 THEN 0 ELSE dm.total_discount_amt / dm.total_sales_price END) < 0.05 THEN 'Low'
        WHEN (CASE WHEN dm.total_sales_price = 0 THEN 0 ELSE dm.total_discount_amt / dm.total_sales_price END) BETWEEN 0.05 AND 0.15 THEN 'Medium'
        ELSE 'High'
    END AS discount_category,
    RANK() OVER (PARTITION BY dm.d_date ORDER BY
        CASE
            WHEN (CASE WHEN dm.total_sales_price = 0 THEN 0 ELSE dm.total_discount_amt / dm.total_sales_price END) < 0.05 THEN 0
            WHEN (CASE WHEN dm.total_sales_price = 0 THEN 0 ELSE dm.total_discount_amt / dm.total_sales_price END) BETWEEN 0.05 AND 0.15 THEN 1
            ELSE 2
        END DESC) AS discount_rank
FROM daily_metrics dm
WHERE dm.total_net_paid > 0
ORDER BY dm.d_date DESC, discount_rank
