WITH max_year_cte AS (
    SELECT max(d_year) AS max_year
    FROM date_dim
)
SELECT
    d.d_year,
    hd.hd_income_band_sk,
    SUM(cr.cr_net_loss) AS total_catalog_net_loss,
    SUM(wr.wr_net_loss) AS total_web_net_loss,
    COUNT(DISTINCT cr.cr_order_number) AS catalog_return_orders,
    COUNT(DISTINCT ws.ws_order_number) AS web_return_orders,
    SUM(l_item_sales.item_total_sales) AS total_sales_by_item,
    CONCAT('Year_', CAST(d.d_year AS varchar)) AS year_label,
    CASE WHEN regexp_like(d.d_date_id, '^AAAA') THEN 'A_prefix' ELSE 'Other' END AS date_id_category,
    substr(s.s_store_name, 1, 10) AS store_name_prefix
FROM catalog_returns cr
JOIN catalog_sales cs
    ON cr.cr_order_number = cs.cs_order_number
   AND cr.cr_item_sk = cs.cs_item_sk
JOIN date_dim d
    ON cr.cr_returned_date_sk = d.d_date_sk
JOIN household_demographics hd
    ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
LEFT JOIN store s
    ON s.s_closed_date_sk = d.d_date_sk
LEFT JOIN LATERAL (
    SELECT sum(cs2.cs_ext_sales_price) AS item_total_sales
    FROM catalog_sales cs2
    WHERE cs2.cs_item_sk = cr.cr_item_sk
) l_item_sales ON true
JOIN web_returns wr
    ON wr.wr_order_number = cr.cr_order_number
JOIN web_sales ws
    ON ws.ws_order_number = wr.wr_order_number
   AND ws.ws_item_sk = wr.wr_item_sk
WHERE
    cr.cr_return_amount > (SELECT avg(cr_return_amount) FROM catalog_returns)
    AND d.d_year = (SELECT max_year FROM max_year_cte)
    AND s.s_store_name LIKE '%Store%'
    AND EXISTS (
        SELECT 1
        FROM web_returns wr2
        WHERE wr2.wr_order_number = ws.ws_order_number
          AND wr2.wr_return_quantity > 5
    )
GROUP BY
    d.d_year,
    hd.hd_income_band_sk,
    CONCAT('Year_', CAST(d.d_year AS varchar)),
    CASE WHEN regexp_like(d.d_date_id, '^AAAA') THEN 'A_prefix' ELSE 'Other' END,
    substr(s.s_store_name, 1, 10)
ORDER BY total_catalog_net_loss DESC
LIMIT 100
