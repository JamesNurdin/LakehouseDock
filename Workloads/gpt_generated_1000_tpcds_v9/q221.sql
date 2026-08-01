WITH sampled_returns AS (
    SELECT *
    FROM catalog_returns
    TABLESAMPLE BERNOULLI (5)
)

SELECT
    s.s_market_manager AS market_manager,
    i.i_category AS category,
    CASE WHEN cr.cr_net_loss > 100 THEN 'High' ELSE 'Low' END AS loss_class,
    CONCAT(i.i_brand, '-', i.i_color) AS brand_color,
    SUBSTRING(cp.cp_description, 1, 20) AS short_desc,
    SUM(cr.cr_return_amount) AS total_return_amount,
    SUM(cr.cr_net_loss) AS total_net_loss,
    COUNT(*) AS return_count
FROM sampled_returns cr
JOIN date_dim d
    ON cr.cr_returned_date_sk = d.d_date_sk
JOIN item i
    ON cr.cr_item_sk = i.i_item_sk
JOIN catalog_page cp
    ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
JOIN store s
    ON s.s_closed_date_sk = d.d_date_sk
WHERE d.d_year = 2001
  AND i.i_item_desc LIKE '%large%'
GROUP BY
    s.s_market_manager,
    i.i_category,
    CASE WHEN cr.cr_net_loss > 100 THEN 'High' ELSE 'Low' END,
    CONCAT(i.i_brand, '-', i.i_color),
    SUBSTRING(cp.cp_description, 1, 20)

UNION

SELECT
    s.s_market_manager AS market_manager,
    i.i_category AS category,
    CASE WHEN cr.cr_net_loss > 100 THEN 'High' ELSE 'Low' END AS loss_class,
    CONCAT(i.i_brand, '-', i.i_color) AS brand_color,
    SUBSTRING(cp.cp_description, 1, 20) AS short_desc,
    SUM(cr.cr_return_amount) AS total_return_amount,
    SUM(cr.cr_net_loss) AS total_net_loss,
    COUNT(*) AS return_count
FROM sampled_returns cr
JOIN date_dim d
    ON cr.cr_returned_date_sk = d.d_date_sk
JOIN item i
    ON cr.cr_item_sk = i.i_item_sk
JOIN catalog_page cp
    ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
JOIN store s
    ON s.s_closed_date_sk = d.d_date_sk
WHERE d.d_year = 2001
  AND regexp_like(i.i_product_name, '^A[0-9]')
GROUP BY
    s.s_market_manager,
    i.i_category,
    CASE WHEN cr.cr_net_loss > 100 THEN 'High' ELSE 'Low' END,
    CONCAT(i.i_brand, '-', i.i_color),
    SUBSTRING(cp.cp_description, 1, 20)

ORDER BY total_net_loss DESC, market_manager
LIMIT 100
