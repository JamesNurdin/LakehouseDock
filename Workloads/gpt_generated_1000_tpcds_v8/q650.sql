WITH
filtered_items AS (
    SELECT
        i.i_item_sk,
        i.i_item_desc,
        i.i_brand,
        i.i_category,
        regexp_extract(i.i_item_desc, '(\\w+)') AS first_word,
        CASE
            WHEN regexp_like(i.i_item_desc, '[0-9]{4}') THEN 'HasYear'
            ELSE 'NoYear'
        END AS year_flag
    FROM item i
    WHERE i.i_item_desc LIKE '%steel%'
),

sales_agg AS (
    SELECT
        cs.cs_bill_customer_sk AS cust_sk,
        COUNT(*) AS num_orders,
        SUM(cs.cs_net_paid_inc_tax) AS total_paid,
        AVG(cs.cs_quantity) AS avg_qty
    FROM catalog_sales cs
    WHERE cs.cs_net_paid_inc_tax > 1000
    GROUP BY cs.cs_bill_customer_sk
),

full_join_cc_store AS (
    SELECT
        cc.cc_call_center_id,
        cc.cc_state,
        cc.cc_country,
        s.s_store_id,
        s.s_state,
        s.s_country
    FROM call_center cc
    FULL OUTER JOIN store s
        ON cc.cc_state = s.s_state
        AND cc.cc_country = s.s_country
    WHERE (cc.cc_name LIKE '%Center%') OR (s.s_store_name LIKE '%Store%')
)

SELECT
    c.c_customer_id,
    CONCAT(c.c_first_name, ' ', c.c_last_name) AS customer_name,
    CASE
        WHEN c.c_preferred_cust_flag = 'Y' THEN 'Preferred'
        ELSE 'Standard'
    END AS customer_type,
    COALESCE(fj.cc_call_center_id, 'NoCallCenter') AS call_center_id,
    COALESCE(fj.s_store_id, 'NoStore') AS store_id,
    fi.first_word,
    fi.year_flag,
    sa.num_orders,
    sa.total_paid,
    (
        SELECT SUM(cs3.cs_net_paid_inc_tax)
        FROM catalog_sales cs3
        WHERE cs3.cs_bill_customer_sk = c.c_customer_sk
    ) AS cust_total_paid_all_time
FROM customer c
LEFT JOIN sales_agg sa
    ON c.c_customer_sk = sa.cust_sk
LEFT JOIN customer_address ca
    ON c.c_current_addr_sk = ca.ca_address_sk
LEFT JOIN full_join_cc_store fj
    ON fj.cc_state = ca.ca_state OR fj.s_state = ca.ca_state
LEFT JOIN filtered_items fi
    ON fi.i_item_sk IN (
        SELECT cs.cs_item_sk
        FROM catalog_sales cs
        WHERE cs.cs_quantity > 5
        INTERSECT
        SELECT i2.i_item_sk
        FROM filtered_items i2
        WHERE i2.year_flag = 'HasYear'
    )
WHERE
    LOWER(CONCAT(c.c_first_name, c.c_last_name)) LIKE '%smith%'
    AND EXISTS (
        SELECT 1
        FROM promotion p
        WHERE p.p_promo_name LIKE '%Discount%'
          AND p.p_item_sk = fi.i_item_sk
    )
ORDER BY sa.total_paid DESC
OFFSET 0
LIMIT 100
