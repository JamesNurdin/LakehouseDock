WITH sales_agg AS (
    SELECT
        cs_bill_addr_sk,
        cs_promo_sk,
        SUM(cs_net_paid) AS total_net_paid,
        SUM(cs_quantity) AS total_qty,
        COUNT(*) AS order_cnt
    FROM catalog_sales
    WHERE cs_quantity > 0
      AND cs_net_paid > 0
      AND cs_sold_date_sk BETWEEN 2450000 AND 2450100
      AND cs_ship_mode_sk IS NOT NULL
    GROUP BY cs_bill_addr_sk, cs_promo_sk
)
SELECT
    p.p_promo_id,
    p.p_promo_name,
    ca.ca_city,
    ca.ca_state,
    COALESCE(sa.total_net_paid, 0)      AS total_net_paid,
    COALESCE(sa.total_qty, 0)           AS total_qty,
    li.distinct_items,
    ROW_NUMBER() OVER (PARTITION BY p.p_promo_id ORDER BY COALESCE(sa.total_net_paid, 0) DESC) AS promo_rank,
    (
        SELECT COUNT(*)
        FROM catalog_sales cs2
        WHERE cs2.cs_bill_addr_sk = ca.ca_address_sk
    ) AS bills_per_address
FROM sales_agg sa
RIGHT OUTER JOIN promotion p
    ON sa.cs_promo_sk = p.p_promo_sk
LEFT JOIN customer_address ca
    ON sa.cs_bill_addr_sk = ca.ca_address_sk
LEFT JOIN LATERAL (
    SELECT COUNT(DISTINCT cs_item_sk) AS distinct_items
    FROM catalog_sales cs4
    WHERE cs4.cs_promo_sk = p.p_promo_sk
) li ON TRUE
WHERE
    p.p_channel_catalog = 'N'
    AND p.p_response_target >= 1
    AND ca.ca_state IN ('CA', 'TX', 'NY')
    AND ca.ca_location_type = 'single family'
    AND EXISTS (
        SELECT 1
        FROM catalog_sales cs3
        WHERE cs3.cs_ship_addr_sk = ca.ca_address_sk
          AND cs3.cs_promo_sk = p.p_promo_sk
          AND cs3.cs_net_paid > 0
    )
ORDER BY total_net_paid DESC
OFFSET 0
LIMIT 100
