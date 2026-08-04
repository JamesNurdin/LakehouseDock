-- goal: Analyze net sales by year, category, state and income band for a sampled set of store sales, while filtering out items that have any web returns, comparing sales to catalog sales, excluding stores with no sales, and incorporating inventory and warehouse information.
WITH
sampled_sales AS (
    SELECT *
    FROM store_sales TABLESAMPLE BERNOULLI (10)
),
inv_wh AS (
    SELECT
        inv.inv_item_sk,
        inv.inv_quantity_on_hand,
        w.w_warehouse_name,
        w.w_warehouse_sk
    FROM inventory inv
    FULL OUTER JOIN warehouse w
        ON inv.inv_warehouse_sk = w.w_warehouse_sk
),
store_without_sales AS (
    SELECT s_store_id
    FROM store
    EXCEPT
    SELECT st.s_store_id
    FROM store_sales ss
    JOIN store st ON ss.ss_store_sk = st.s_store_sk
),
joined AS (
    SELECT
        ss.ss_sold_date_sk,
        ss.ss_sold_time_sk,
        ss.ss_item_sk,
        ss.ss_hdemo_sk,
        ss.ss_addr_sk,
        ss.ss_store_sk,
        ss.ss_promo_sk,
        ss.ss_net_paid,
        d.d_date,
        d.d_year,
        t.t_hour,
        i.i_category,
        hd.hd_income_band_sk,
        ca.ca_state,
        st.s_store_name,
        p.p_promo_name,
        inv_wh.inv_quantity_on_hand,
        inv_wh.w_warehouse_name,
        cs.cs_net_paid,
        wr.wr_return_amt
    FROM sampled_sales ss
    LEFT JOIN date_dim d
        ON ss.ss_sold_date_sk = d.d_date_sk
    LEFT JOIN time_dim t
        ON ss.ss_sold_time_sk = t.t_time_sk
    LEFT JOIN item i
        ON ss.ss_item_sk = i.i_item_sk
    LEFT JOIN household_demographics hd
        ON ss.ss_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN customer_address ca
        ON ss.ss_addr_sk = ca.ca_address_sk
    LEFT JOIN store st
        ON ss.ss_store_sk = st.s_store_sk
    LEFT JOIN promotion p
        ON ss.ss_promo_sk = p.p_promo_sk
    LEFT JOIN inv_wh
        ON ss.ss_item_sk = inv_wh.inv_item_sk
    LEFT JOIN catalog_sales cs
        ON ss.ss_sold_date_sk = cs.cs_sold_date_sk
        AND ss.ss_item_sk = cs.cs_item_sk
    LEFT JOIN web_returns wr
        ON ss.ss_sold_date_sk = wr.wr_returned_date_sk
        AND ss.ss_item_sk = wr.wr_item_sk
    WHERE NOT EXISTS (
        SELECT 1
        FROM web_returns wr2
        WHERE wr2.wr_item_sk = ss.ss_item_sk
          AND wr2.wr_returned_date_sk = ss.ss_sold_date_sk
    )
      AND ss.ss_net_paid > (
          SELECT COALESCE(MAX(cs2.cs_net_paid), 0)
          FROM catalog_sales cs2
          WHERE cs2.cs_sold_date_sk = ss.ss_sold_date_sk
      )
      AND st.s_store_id NOT IN (SELECT s_store_id FROM store_without_sales)
)
SELECT
    d_year,
    i_category,
    ca_state,
    hd_income_band_sk,
    COUNT(*) AS txn_count,
    SUM(ss_net_paid) AS total_net_paid,
    SUM(COALESCE(cs_net_paid, 0)) AS total_catalog_net_paid,
    SUM(COALESCE(wr_return_amt, 0)) AS total_web_return_amt,
    AVG(inv_quantity_on_hand) AS avg_inventory_on_hand
FROM joined
GROUP BY
    d_year,
    i_category,
    ca_state,
    hd_income_band_sk
ORDER BY total_net_paid DESC
LIMIT 100
