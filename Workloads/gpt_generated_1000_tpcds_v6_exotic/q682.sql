WITH catalog_cte AS (
    SELECT
        cr.cr_item_sk,
        i.i_category AS i_category,
        i.i_brand AS i_brand,
        cr.cr_return_quantity AS return_quantity,
        cr.cr_return_amount AS return_amount
    FROM catalog_returns cr
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    JOIN customer_address ca_refunded ON cr.cr_refunded_addr_sk = ca_refunded.ca_address_sk
    JOIN customer_demographics cd_refunded ON cr.cr_refunded_cdemo_sk = cd_refunded.cd_demo_sk
    LEFT JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
    WHERE cr.cr_return_amount > 50.00
      AND cr.cr_ship_mode_sk IN (2, 9, 15)
      AND ca_refunded.ca_state = 'CA'
      AND cd_refunded.cd_gender = 'F'
      AND w.w_country = 'United States'
),
web_cte AS (
    SELECT
        wr.wr_item_sk,
        i.i_category AS i_category,
        i.i_brand AS i_brand,
        wr.wr_return_quantity AS return_quantity,
        wr.wr_return_amt AS return_amount
    FROM web_returns wr
    JOIN item i ON wr.wr_item_sk = i.i_item_sk
    JOIN customer_address ca_refunded ON wr.wr_refunded_addr_sk = ca_refunded.ca_address_sk
    JOIN customer_demographics cd_refunded ON wr.wr_refunded_cdemo_sk = cd_refunded.cd_demo_sk
    WHERE wr.wr_return_amt > 50.00
      AND ca_refunded.ca_state = 'CA'
      AND cd_refunded.cd_gender = 'F'
      AND wr.wr_return_quantity BETWEEN 1 AND 5
      AND wr.wr_return_tax < 20.00
)
SELECT
    combined.i_category,
    combined.i_brand,
    SUM(combined.return_quantity) AS total_return_qty,
    SUM(combined.return_amount) AS total_return_amount,
    AVG(combined.return_amount) AS avg_return_amount,
    COUNT(*) AS return_rows,
    (SELECT AVG(cr_return_amount) FROM catalog_returns WHERE cr_return_amount > 0) AS avg_catalog_return_amount
FROM (
    SELECT i_category, i_brand, return_quantity, return_amount
    FROM catalog_cte
    UNION ALL
    SELECT i_category, i_brand, return_quantity, return_amount
    FROM web_cte
) AS combined
GROUP BY combined.i_category, combined.i_brand
HAVING SUM(combined.return_amount) > 1000
ORDER BY total_return_amount DESC
LIMIT 100
