WITH sales_agg AS (
    SELECT
        cs.cs_bill_customer_sk   AS cust_sk,
        cs.cs_catalog_page_sk    AS page_sk,
        cs.cs_item_sk            AS item_sk,
        cs.cs_promo_sk           AS promo_sk,
        t.t_hour                 AS sale_hour,
        SUM(cs.cs_net_paid)      AS total_net_paid,
        SUM(cs.cs_quantity)      AS total_qty,
        COUNT(*)                 AS txn_count
    FROM catalog_sales cs
    JOIN time_dim t
      ON cs.cs_sold_time_sk = t.t_time_sk
    WHERE cs.cs_quantity > 5
      AND cs.cs_net_paid > 100
      AND cs.cs_sales_price > 20
      AND t.t_hour BETWEEN 9 AND 17
    GROUP BY cs.cs_bill_customer_sk,
             cs.cs_catalog_page_sk,
             cs.cs_item_sk,
             cs.cs_promo_sk,
             t.t_hour
)
SELECT
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    ca.ca_state,
    cp.cp_department,
    i.i_category,
    sa.total_net_paid,
    sa.total_qty,
    sa.txn_count,
    RANK() OVER (PARTITION BY sa.sale_hour ORDER BY sa.total_net_paid DESC) AS rank_by_hour,
    CASE
        WHEN EXISTS (
            SELECT 1
            FROM promotion p
            WHERE p.p_promo_sk = sa.promo_sk
              AND p.p_discount_active = 'Y'
              AND p.p_channel_email = 'Y'
        ) THEN 'PromoActive'
        ELSE 'NoPromo'
    END AS promo_status
FROM sales_agg sa
JOIN customer c
  ON sa.cust_sk = c.c_customer_sk
JOIN customer_address ca
  ON c.c_current_addr_sk = ca.ca_address_sk
JOIN catalog_page cp
  ON sa.page_sk = cp.cp_catalog_page_sk
JOIN item i
  ON sa.item_sk = i.i_item_sk
WHERE c.c_birth_year BETWEEN 1970 AND 1990
  AND ca.ca_country = 'United States'
  AND cp.cp_type = 'Online'
  AND i.i_brand = 'Brand#12'
ORDER BY sa.sale_hour, rank_by_hour
LIMIT 100
