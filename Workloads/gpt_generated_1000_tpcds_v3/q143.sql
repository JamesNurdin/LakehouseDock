WITH filtered_sales AS (
    SELECT
        ws.ws_item_sk,
        ws.ws_bill_customer_sk,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(*) AS order_cnt
    FROM web_sales ws
    JOIN date_dim d
        ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 1998
      AND ws.ws_item_sk IN (
            SELECT inv.inv_item_sk
            FROM inventory inv
            JOIN date_dim d_inv
                ON inv.inv_date_sk = d_inv.d_date_sk
            WHERE inv.inv_quantity_on_hand > 50
              AND d_inv.d_year = 1998
        )
    GROUP BY ws.ws_item_sk, ws.ws_bill_customer_sk
)
SELECT
    i.i_item_id,
    i.i_product_name,
    CONCAT(i.i_brand, '-', SUBSTR(i.i_product_name, 1, 10)) AS brand_product_snippet,
    REGEXP_EXTRACT(i.i_product_name, '([0-9]{3})', 1) AS product_code,
    fs.total_sales,
    fs.order_cnt,
    (
        SELECT MAX(ib.ib_upper_bound)
        FROM income_band ib
        JOIN household_demographics hd
            ON ib.ib_income_band_sk = hd.hd_income_band_sk
        WHERE hd.hd_demo_sk = c.c_current_hdemo_sk
    ) AS max_income_upper
FROM filtered_sales fs
JOIN item i
    ON fs.ws_item_sk = i.i_item_sk
JOIN customer c
    ON fs.ws_bill_customer_sk = c.c_customer_sk
WHERE REGEXP_LIKE(i.i_product_name, '[A-Z]{2}[0-9]{3}')
  AND i.i_product_name LIKE '%COFFEE%'
ORDER BY fs.total_sales DESC
LIMIT 100
