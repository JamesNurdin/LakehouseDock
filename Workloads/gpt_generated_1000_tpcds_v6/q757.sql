/*
Goal: Combine catalog sales and store return data, enrich with item and demographic dimensions, and compare total revenue (or loss) by store. The query joins all seven tables, re‑uses the ITEM, CUSTOMER_ADDRESS, HOUSEHOLD_DEMOGRAPHICS and STORE tables under multiple aliases to create more than nine join clauses. Two sub‑queries (catalog side and return side) are UNION‑ALL‑ed, then window functions compute the total per store and rank the stores.
*/
WITH
-- Catalog (and web‑sales style) side – joins item, address and household dimensions multiple times
sales_sub AS (
    SELECT
        CAST(NULL AS VARCHAR)               AS store_id,
        i1.i_category                        AS category,
        SUM(cs.cs_net_paid_inc_ship)        AS amount,
        'catalog'                           AS src
    FROM catalog_sales cs
    JOIN item i1        ON cs.cs_item_sk = i1.i_item_sk                -- 1st join to ITEM
    JOIN item i1b       ON cs.cs_item_sk = i1b.i_item_sk               -- extra join to ITEM (different alias)
    JOIN customer_address ca_bill ON cs.cs_bill_addr_sk = ca_bill.ca_address_sk   -- join to ADDRESS
    JOIN household_demographics hd_bill ON cs.cs_bill_hdemo_sk = hd_bill.hd_demo_sk   -- join to DEMO
    JOIN household_demographics hd_bill2 ON cs.cs_bill_hdemo_sk = hd_bill2.hd_demo_sk   -- extra join to DEMO (different alias)
    GROUP BY i1.i_category
),

-- Store returns side – also joins ITEM, STORE, ADDRESS and DEMO twice each
returns_sub AS (
    SELECT
        s.s_store_id                         AS store_id,
        i2.i_category                        AS category,
        SUM(sr.sr_return_amt)               AS amount,
        'store_return'                      AS src
    FROM store_returns sr
    JOIN item i2        ON sr.sr_item_sk = i2.i_item_sk                -- 1st join to ITEM
    JOIN item i2b       ON sr.sr_item_sk = i2b.i_item_sk               -- extra join to ITEM (different alias)
    JOIN store s        ON sr.sr_store_sk = s.s_store_sk                -- 1st join to STORE
    JOIN store s2       ON sr.sr_store_sk = s2.s_store_sk               -- extra join to STORE (different alias)
    JOIN customer_address ca_sr ON sr.sr_addr_sk = ca_sr.ca_address_sk   -- join to ADDRESS
    JOIN household_demographics hd_sr ON sr.sr_hdemo_sk = hd_sr.hd_demo_sk   -- join to DEMO
    GROUP BY s.s_store_id, i2.i_category
),

-- Union the two prepared result sets
combined AS (
    SELECT * FROM sales_sub
    UNION ALL
    SELECT * FROM returns_sub
),

-- Compute total amount per store (store_id may be NULL for catalog rows)
with_total AS (
    SELECT
        store_id,
        category,
        amount,
        src,
        SUM(amount) OVER (PARTITION BY store_id) AS store_total
    FROM combined
)
SELECT
    store_id,
    category,
    amount,
    src,
    store_total,
    RANK() OVER (ORDER BY store_total DESC) AS store_rank
FROM with_total
ORDER BY store_total DESC, amount DESC
LIMIT 100
