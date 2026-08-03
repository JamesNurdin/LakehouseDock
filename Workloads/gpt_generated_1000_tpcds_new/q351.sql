WITH
sales_cte AS (
    SELECT
        cs.cs_sold_date_sk,
        d.d_year AS sold_year,
        cs.cs_item_sk,
        i.i_item_desc,
        cs.cs_quantity,
        cs.cs_sales_price,
        c.c_customer_sk,
        ca.ca_state,
        cd.cd_gender,
        hd.hd_income_band_sk,
        cc.cc_name,
        cp.cp_type
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
    JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
),
returns_cte AS (
    SELECT
        sr.sr_returned_date_sk,
        d2.d_year AS return_year,
        sr.sr_item_sk,
        i2.i_item_desc,
        sr.sr_return_quantity,
        sr.sr_return_amt,
        st.s_store_sk,
        st.s_store_name,
        cd2.cd_gender,
        hd2.hd_income_band_sk,
        ca2.ca_state
    FROM store_returns sr
    JOIN date_dim d2 ON sr.sr_returned_date_sk = d2.d_date_sk
    JOIN item i2 ON sr.sr_item_sk = i2.i_item_sk
    JOIN store st ON sr.sr_store_sk = st.s_store_sk
    JOIN customer_demographics cd2 ON sr.sr_cdemo_sk = cd2.cd_demo_sk
    JOIN household_demographics hd2 ON sr.sr_hdemo_sk = hd2.hd_demo_sk
    JOIN customer_address ca2 ON sr.sr_addr_sk = ca2.ca_address_sk
),
union_sales_returns AS (
    SELECT cs_item_sk AS item_sk,
           sold_year AS year,
           cs_quantity AS qty,
           'sale' AS src
    FROM sales_cte
    UNION DISTINCT
    SELECT sr_item_sk AS item_sk,
           return_year AS year,
           sr_return_quantity AS qty,
           'return' AS src
    FROM returns_cte
),
inventory_cte AS (
    SELECT
        inv.inv_item_sk,
        inv.inv_quantity_on_hand
    FROM inventory inv
    JOIN date_dim d3 ON inv.inv_date_sk = d3.d_date_sk
    JOIN item i3 ON inv.inv_item_sk = i3.i_item_sk
),
full_store_cte AS (
    SELECT
        s.s_store_sk,
        s.s_store_name,
        sr.sr_returned_date_sk,
        sr.sr_return_quantity
    FROM store s
    FULL OUTER JOIN store_returns sr ON s.s_store_sk = sr.sr_store_sk
),
final AS (
    SELECT
        us.item_sk,
        us.year,
        us.src,
        us.qty,
        inv.inv_quantity_on_hand,
        (SELECT avg(inv2.inv_quantity_on_hand)
         FROM inventory inv2
         WHERE inv2.inv_item_sk = us.item_sk) AS avg_qty_on_hand,
        unnested.expanded_qty
    FROM union_sales_returns us
    LEFT JOIN inventory_cte inv ON us.item_sk = inv.inv_item_sk
    CROSS JOIN LATERAL (
        SELECT val AS expanded_qty
        FROM UNNEST(ARRAY[us.qty, COALESCE(inv.inv_quantity_on_hand, 0)]) AS t(val)
    ) unnested
    WHERE EXISTS (
        SELECT 1
        FROM web_page wp
        JOIN date_dim dw ON wp.wp_creation_date_sk = dw.d_date_sk
        WHERE wp.wp_customer_sk = (
            SELECT c.c_customer_sk
            FROM customer c
            WHERE c.c_customer_id = '123'
            LIMIT 1
        )
          AND dw.d_year = us.year
    )
)
SELECT
    item_sk,
    year,
    src,
    SUM(qty) AS total_qty,
    SUM(inv_quantity_on_hand) AS total_inventory_qty,
    AVG(avg_qty_on_hand) AS avg_inventory_qty,
    COUNT(DISTINCT expanded_qty) AS distinct_expanded_qty
FROM final
GROUP BY item_sk, year, src
ORDER BY total_qty DESC
LIMIT 100
