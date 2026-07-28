WITH combined AS (
    SELECT
        d.d_date AS return_date,
        cr.cr_return_amount AS return_amount,
        w.w_warehouse_name AS warehouse_name,
        r.r_reason_desc AS reason_desc,
        (SELECT AVG(cr2.cr_return_amount)
         FROM catalog_returns cr2
         WHERE cr2.cr_warehouse_sk = cr.cr_warehouse_sk) AS avg_warehouse_return,
        ROW_NUMBER() OVER (PARTITION BY w.w_warehouse_name ORDER BY cr.cr_return_amount DESC) AS rn
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
    WHERE d.d_year = 2020
      AND r.r_reason_desc LIKE '%damaged%'

    UNION ALL

    SELECT
        d.d_date AS return_date,
        wr.wr_return_amt AS return_amount,
        w.w_warehouse_name AS warehouse_name,
        r.r_reason_desc AS reason_desc,
        (SELECT AVG(wr2.wr_return_amt)
         FROM web_returns wr2
         WHERE wr2.wr_reason_sk = wr.wr_reason_sk) AS avg_warehouse_return,
        ROW_NUMBER() OVER (PARTITION BY w.w_warehouse_name ORDER BY wr.wr_return_amt DESC) AS rn
    FROM web_returns wr
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
    JOIN web_sales ws ON wr.wr_order_number = ws.ws_order_number
    JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    WHERE d.d_year = 2020
      AND r.r_reason_desc LIKE '%damaged%'
      AND EXISTS (
            SELECT 1
            FROM web_sales ws2
            WHERE ws2.ws_order_number = wr.wr_order_number
              AND ws2.ws_quantity > 1
          )
)
SELECT
    return_date,
    return_amount,
    warehouse_name,
    reason_desc,
    avg_warehouse_return,
    rn
FROM combined
ORDER BY return_amount DESC
LIMIT 100
