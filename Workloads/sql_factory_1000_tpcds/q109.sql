WITH promo_sales AS (
    SELECT
        p.p_promo_id,
        p.p_promo_name,
        p.p_response_target,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        AVG(ws.ws_ext_discount_amt) AS avg_discount_amt,
        COUNT(DISTINCT ws.ws_web_site_sk) AS site_count,
        MAX(CASE WHEN ws.ws_ext_discount_amt > 0 THEN 1 ELSE 0 END) AS has_discount_flag,
        AVG(cd_bill.cd_purchase_estimate) AS avg_purchase_estimate
    FROM promotion p
    JOIN web_sales ws
        ON ws.ws_promo_sk = p.p_promo_sk
    JOIN customer_demographics cd_bill
        ON ws.ws_bill_cdemo_sk = cd_bill.cd_demo_sk
    GROUP BY p.p_promo_id, p.p_promo_name, p.p_response_target
)
SELECT
    p_promo_id,
    p_promo_name,
    total_quantity,
    total_sales,
    avg_discount_amt,
    site_count,
    CASE
        WHEN p_response_target > 0 THEN CAST(total_quantity AS double) / p_response_target
        ELSE NULL
    END AS effectiveness,
    DENSE_RANK() OVER (
        ORDER BY CASE WHEN p_response_target > 0 THEN CAST(total_quantity AS double) / p_response_target ELSE -1 END DESC
    ) AS effectiveness_rank,
    CASE WHEN has_discount_flag = 1 THEN 'Has Discount' ELSE 'No Discount' END AS discount_flag,
    avg_purchase_estimate
FROM promo_sales
ORDER BY effectiveness_rank
