WITH avg_promo_cost AS (
    SELECT avg(p_cost) AS avg_cost
    FROM promotion
    WHERE p_discount_active = 'Y'
)
SELECT *
FROM (
    SELECT
        ws.ws_bill_customer_sk AS customer_sk,
        c.c_first_name AS first_name,
        c.c_last_name AS last_name,
        SUM(ws.ws_ext_sales_price) AS total_sales_amount,
        CAST(NULL AS decimal(7,2)) AS total_return_amount,
        'sales' AS record_type,
        (SELECT avg_cost FROM avg_promo_cost) AS avg_active_promo_cost
    FROM web_sales ws
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    WHERE ws.ws_sold_date_sk BETWEEN 2450815 AND 2451200
      AND p.p_discount_active = 'Y'
    GROUP BY ws.ws_bill_customer_sk, c.c_first_name, c.c_last_name

    UNION ALL

    SELECT
        wr.wr_returning_customer_sk AS customer_sk,
        c.c_first_name AS first_name,
        c.c_last_name AS last_name,
        CAST(NULL AS decimal(7,2)) AS total_sales_amount,
        SUM(wr.wr_return_amt) AS total_return_amount,
        'return' AS record_type,
        (SELECT avg_cost FROM avg_promo_cost) AS avg_active_promo_cost
    FROM web_returns wr
    JOIN customer c ON wr.wr_returning_customer_sk = c.c_customer_sk
    JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
    WHERE wr.wr_returned_date_sk BETWEEN 2450815 AND 2451200
      AND r.r_reason_desc LIKE '%defect%'
    GROUP BY wr.wr_returning_customer_sk, c.c_first_name, c.c_last_name
) combined
ORDER BY
    COALESCE(total_sales_amount, 0) DESC,
    COALESCE(total_return_amount, 0) DESC
LIMIT 100
