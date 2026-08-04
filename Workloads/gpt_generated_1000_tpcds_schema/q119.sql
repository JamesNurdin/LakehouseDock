WITH catalog_top AS (
    SELECT i_item_id,
           i_brand,
           cs_net_paid_inc_ship_tax
    FROM (
        SELECT i.i_item_id,
               i.i_brand,
               cs.cs_net_paid_inc_ship_tax,
               row_number() OVER (PARTITION BY i.i_brand ORDER BY cs.cs_net_paid_inc_ship_tax DESC) AS rn
        FROM catalog_sales cs
        JOIN item i ON cs.cs_item_sk = i.i_item_sk
        WHERE cs.cs_quantity > 5
          AND cs.cs_ext_discount_amt > (SELECT avg(cs2.cs_ext_discount_amt) FROM catalog_sales cs2)
    )
    WHERE rn <= 5
),
store_top AS (
    SELECT i_item_id,
           i_brand,
           ss_net_paid
    FROM (
        SELECT i.i_item_id,
               i.i_brand,
               ss.ss_net_paid,
               row_number() OVER (PARTITION BY i.i_brand ORDER BY ss.ss_net_paid DESC) AS rn
        FROM store_sales ss
        JOIN item i ON ss.ss_item_sk = i.i_item_sk
        WHERE ss.ss_quantity > 5
          AND ss.ss_ext_discount_amt > (SELECT avg(cs2.cs_ext_discount_amt) FROM catalog_sales cs2)
    )
    WHERE rn <= 5
)
SELECT ct.i_item_id,
       ct.i_brand,
       ct.cs_net_paid_inc_ship_tax AS net_paid
FROM catalog_top ct
INTERSECT
SELECT st.i_item_id,
       st.i_brand,
       st.ss_net_paid AS net_paid
FROM store_top st
ORDER BY i_brand, net_paid DESC
LIMIT 100
