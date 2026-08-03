/*
Goal: Identify, for each warehouse, the top 5 return reasons (by total return amount including tax) where the reason description mentions the word "product" (case‑insensitive) and the reason ID matches a specific pattern. Only keep return rows that have a matching catalog return for the same customer, warehouse and reason. Classify each aggregated reason as High or Low based on a $1,000 threshold and rank the reasons per warehouse.
*/
WITH filtered_returns AS (
    SELECT
        wr.wr_returning_customer_sk,
        ws.ws_warehouse_sk,
        w.w_warehouse_name,
        r.r_reason_desc,
        wr.wr_return_amt_inc_tax,
        CONCAT(w.w_warehouse_name, ': ', r.r_reason_desc) AS warehouse_reason
    FROM web_returns wr
    INNER JOIN web_sales ws
        ON wr.wr_order_number = ws.ws_order_number
        AND wr.wr_item_sk = ws.ws_item_sk
    INNER JOIN warehouse w
        ON ws.ws_warehouse_sk = w.w_warehouse_sk
    INNER JOIN reason r
        ON wr.wr_reason_sk = r.r_reason_sk
    WHERE regexp_like(r.r_reason_desc, '(?i)product')               -- string processing with regex
      AND r.r_reason_id LIKE 'AAAAAAA%PAAAAAAA'                     -- pattern matching with LIKE
      AND EXISTS (
            SELECT 1
            FROM catalog_returns cr
            WHERE cr.cr_refunded_customer_sk = wr.wr_refunded_customer_sk
              AND cr.cr_warehouse_sk = ws.ws_warehouse_sk
              AND cr.cr_reason_sk = wr.wr_reason_sk
        )
),
aggregated AS (
    SELECT
        w_warehouse_name,
        r_reason_desc,
        SUM(wr_return_amt_inc_tax) AS total_return_amount,
        CASE
            WHEN SUM(wr_return_amt_inc_tax) > 1000 THEN 'High'
            ELSE 'Low'
        END AS amount_category,
        ROW_NUMBER() OVER (
            PARTITION BY w_warehouse_name
            ORDER BY SUM(wr_return_amt_inc_tax) DESC
        ) AS rn
    FROM filtered_returns
    GROUP BY w_warehouse_name, r_reason_desc
)
SELECT
    w_warehouse_name,
    r_reason_desc,
    total_return_amount,
    amount_category,
    rn
FROM aggregated
WHERE rn <= 5                         -- top‑k per warehouse (k=5)
ORDER BY w_warehouse_name, rn
