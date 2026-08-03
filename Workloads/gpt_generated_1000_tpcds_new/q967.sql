WITH item_sample AS (
    SELECT *
    FROM item TABLESAMPLE BERNOULLI (10)
    WHERE i_brand = 'Brand#23' -- filter on a specific brand
)
SELECT
    i.i_brand,
    i.i_category,
    p.p_promo_name,
    cp.cp_department,
    COUNT(DISTINCT cs.cs_order_number) AS catalog_orders,
    SUM(cs.cs_ext_sales_price) AS catalog_sales,
    SUM(ss.ss_net_paid) AS store_sales,
    SUM(ws.ws_net_paid) AS web_sales,
    SUM(cs.cs_ext_discount_amt) AS catalog_discount,
    AVG(
        CASE
            WHEN cs.cs_ext_discount_amt > 500 THEN cs.cs_ext_discount_amt
            ELSE 0
        END
    ) AS avg_large_discount,
    MIN(cs.cs_sold_date_sk) AS first_sold_date_sk,
    MAX(cs.cs_sold_date_sk) AS last_sold_date_sk
FROM catalog_sales cs
JOIN catalog_page cp
    ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN warehouse w
    ON cs.cs_warehouse_sk = w.w_warehouse_sk
JOIN item_sample i
    ON cs.cs_item_sk = i.i_item_sk
JOIN promotion p
    ON cs.cs_promo_sk = p.p_promo_sk
JOIN store_sales ss
    ON ss.ss_item_sk = i.i_item_sk
   AND ss.ss_promo_sk = p.p_promo_sk
JOIN store_returns sr
    ON sr.sr_item_sk = ss.ss_item_sk
   AND sr.sr_ticket_number = ss.ss_ticket_number
JOIN web_sales ws
    ON ws.ws_item_sk = i.i_item_sk
   AND ws.ws_promo_sk = p.p_promo_sk
WHERE cs.cs_sold_date_sk BETWEEN 2451910 AND 2451915               -- date range filter
  AND cs.cs_ext_sales_price > 1000                                 -- sales amount filter
  AND p.p_discount_active = 'Y'                                    -- only active promotions
  AND w.w_state = 'CA'                                             -- warehouse in California
  AND i.i_category = 'Electronics'                                 -- specific product category filter
GROUP BY i.i_brand, i.i_category, p.p_promo_name, cp.cp_department
ORDER BY catalog_sales DESC
OFFSET 0 ROWS FETCH NEXT 20 ROWS ONLY
