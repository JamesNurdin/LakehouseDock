WITH max_promo AS (
    SELECT max(d_date_sk) AS max_date_sk
    FROM date_dim
    WHERE d_year = 2002
)

SELECT
    d.d_year,
    i.i_item_id,
    sum(ss.ss_ext_sales_price) AS total_sales,
    CAST(0.0 AS decimal(7,2)) AS total_returns,
    cd.avg_discount
FROM store_sales ss
RIGHT OUTER JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
LEFT JOIN item i ON ss.ss_item_sk = i.i_item_sk
CROSS JOIN LATERAL (
    SELECT avg(cs.cs_ext_discount_amt) AS avg_discount
    FROM catalog_sales cs
    WHERE cs.cs_item_sk = i.i_item_sk
      AND cs.cs_sold_date_sk = d.d_date_sk
) cd
WHERE d.d_year BETWEEN 2001 AND 2002
  AND EXISTS (
        SELECT 1
        FROM promotion p
        WHERE p.p_promo_sk = ss.ss_promo_sk
          AND p.p_end_date_sk > (SELECT max_date_sk FROM max_promo)
    )
GROUP BY d.d_year, i.i_item_id, cd.avg_discount

UNION

SELECT
    d.d_year,
    i.i_item_id,
    CAST(0.0 AS decimal(7,2)) AS total_sales,
    sum(cr.cr_return_amount) AS total_returns,
    CAST(NULL AS decimal(7,2)) AS avg_discount
FROM catalog_returns cr
JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
JOIN item i ON cr.cr_item_sk = i.i_item_sk
WHERE d.d_year = 2002
  AND cr.cr_return_quantity > 10
GROUP BY d.d_year, i.i_item_id

ORDER BY d_year, i_item_id
LIMIT 100
