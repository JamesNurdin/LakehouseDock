WITH raw_join AS (
    SELECT
        cs.cs_net_paid,
        cs.cs_quantity,
        cs.cs_ext_discount_amt,
        cs.cs_ext_tax,
        cs.cs_net_profit,
        i1.i_class,
        i1.i_category,
        i1.i_current_price,
        c_bill.c_customer_id AS bill_customer_id,
        c_ship.c_customer_id AS ship_customer_id,
        sr.sr_return_quantity,
        sr.sr_return_amt,
        inv.inv_quantity_on_hand,
        cp.cp_catalog_number,
        sm.sm_type,
        p.p_promo_name
    FROM catalog_sales cs
    JOIN catalog_page cp
        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN ship_mode sm
        ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN promotion p
        ON cs.cs_promo_sk = p.p_promo_sk
    JOIN item i1
        ON cs.cs_item_sk = i1.i_item_sk
    JOIN customer c_bill
        ON cs.cs_bill_customer_sk = c_bill.c_customer_sk
    JOIN customer c_ship
        ON cs.cs_ship_customer_sk = c_ship.c_customer_sk
    JOIN store_returns sr
        ON sr.sr_item_sk = i1.i_item_sk
    JOIN customer c_return
        ON sr.sr_customer_sk = c_return.c_customer_sk
    JOIN inventory inv
        ON inv.inv_item_sk = i1.i_item_sk
    -- reuse item under two additional aliases
    JOIN item i2
        ON inv.inv_item_sk = i2.i_item_sk
    JOIN item i3
        ON p.p_item_sk = i3.i_item_sk
    WHERE i1.i_current_price > (SELECT AVG(i_current_price) FROM item)
),
agg AS (
    SELECT
        i_class,
        i_category,
        SUM(cs_net_paid) AS total_net_paid,
        COUNT(*) AS sales_cnt,
        AVG(cs_net_paid) AS avg_net_paid
    FROM raw_join
    GROUP BY GROUPING SETS (
        (i_class, i_category),
        (i_class),
        (i_category),
        ()
    )
)
SELECT
    i_class,
    i_category,
    total_net_paid,
    sales_cnt,
    avg_net_paid,
    RANK() OVER (PARTITION BY i_class ORDER BY total_net_paid DESC) AS class_rank
FROM agg
ORDER BY total_net_paid DESC
LIMIT 100
