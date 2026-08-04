WITH inventory_agg AS (
    SELECT
        inv.inv_date_sk,
        inv.inv_item_sk,
        SUM(inv.inv_quantity_on_hand) AS total_qty_on_hand
    FROM inventory inv
    GROUP BY inv.inv_date_sk, inv.inv_item_sk
)
SELECT
    s.s_store_id,
    s.s_store_name,
    i.i_item_id,
    i.i_product_name,
    d_ss.d_date,
    inv_agg.total_qty_on_hand,
    cs.cs_net_profit,
    ss.ss_net_paid,
    CASE
        WHEN p.p_discount_active = 'Y' THEN 'Discounted'
        ELSE 'Regular'
    END AS promo_type,
    RANK() OVER (PARTITION BY s.s_store_id ORDER BY ss.ss_net_paid DESC) AS sales_rank
FROM store_sales ss
JOIN date_dim d_ss
    ON ss.ss_sold_date_sk = d_ss.d_date_sk
JOIN item i
    ON ss.ss_item_sk = i.i_item_sk
JOIN store s
    ON ss.ss_store_sk = s.s_store_sk
JOIN promotion p
    ON ss.ss_promo_sk = p.p_promo_sk
JOIN inventory_agg inv_agg
    ON inv_agg.inv_item_sk = i.i_item_sk
   AND inv_agg.inv_date_sk = d_ss.d_date_sk
JOIN catalog_sales cs
    ON cs.cs_sold_date_sk = d_ss.d_date_sk
   AND cs.cs_item_sk = i.i_item_sk
JOIN catalog_page cp
    ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN web_site w
    ON w.web_open_date_sk = d_ss.d_date_sk
WHERE d_ss.d_year = 1905
  AND i.i_brand_id IN (1, 2, 3)
  AND s.s_country = 'United States'
  AND p.p_discount_active = 'Y'
  AND w.web_site_id LIKE 'W_%'
  AND ss.ss_ticket_number NOT IN (
        SELECT cs_order_number
        FROM catalog_sales
        WHERE cs_order_number IS NOT NULL
    )
ORDER BY sales_rank ASC, d_ss.d_date DESC
LIMIT 100
